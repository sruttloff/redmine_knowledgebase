# Redmine 6.1 validation — Knowledgebase 3.0.0

Validation date: **2026-10-16**. Result: **all documented checks passed; no unresolved failure was found in the tested workflows**.

## Environment

| Component | Version |
| --- | --- |
| Redmine | 6.1.2-stable |
| Rails | 7.2.3 |
| Ruby | 3.3.7 |
| MySQL | 8.4.11 |
| acts-as-taggable-on | 13.0.0 |
| awesome_nested_set | 3.9.0 |
| Browser | Codex integrated Chromium browser |

The local Redmine installation also contains Redmine Tags, Redcase, Redmine UX Toolkit, Contacts/Helpdesk and other plugins. Tests were run against the development instance, with the actual MySQL adapter. No compatibility claim is made for untested adapters or Redmine versions.

## Automated checks

| Check | Result |
| --- | --- |
| `bundle exec rake zeitwerk:check` | Passed; all application constants eager-load. |
| `bundle exec rails runner plugins/redmine_knowledgebase/test/compatibility_smoke.rb` | **91 checks passed**; temporary database records rolled back. |
| `bundle exec rails runner plugins/redmine_knowledgebase/test/reload_smoke.rb` | **Three consecutive reloads passed**; models, associations, macros, attachment object registration and search registration remain valid. |
| `bundle exec ruby plugins/redmine_knowledgebase/test/localization_smoke.rb` | All **16 locale files** parse; refresh utility fills missing keys in temporary copies without changing source locales. |
| `bundle exec ruby plugins/redmine_knowledgebase/test/migration_smoke.rb` with a local administrative connection | Fresh installation and legacy shared-tag scenarios passed in isolated temporary MySQL databases. |
| `bundle exec rake assets:precompile` | Passed. |
| `git diff --check` | Passed. |

The request test uses generated temporary admin and member accounts; it does not update existing user passwords. It isolates uploaded files in a temporary storage directory, compares their bytes, and removes that directory afterwards. The test accounts, roles, projects, categories, articles, ratings, comments, views and taggings are rolled back.

### Request and permission coverage

- Category creation, validation, display, editing, nesting, promotion to root, moving back under a parent and deletion of an empty subtree.
- Rejection of category cycles and deletion of a subtree containing an article.
- Article creation, validation, display, editing, previews and deletion.
- Author protection against mass assignment; updater tracking.
- Tags persist under the modern shared schema and stay separate through an edit-form round trip; tag filtering finds matching articles.
- Plain summaries are escaped; all four wiki macros produce article/category links.
- Ratings persist with a correct average/count; out-of-range and malformed values are rejected.
- Valid comments persist and update their counter; empty comments return validation feedback; moderation decrements the counter.
- Repeat views are deduplicated; full-length IPv6 addresses can be stored.
- Global search finds articles and renders the correct result URL.
- English and German article pages have no missing translations; overview and plugin settings render.
- Missing articles/categories return 404.
- Anonymous read/tag browsing follows the plugin setting; anonymous edit requires login.
- With anonymous access disabled, a normal reader can read but cannot edit, rate, comment, delete articles or create categories.
- Comment/rate permission enables those operations without granting moderation or attachment deletion.
- Manage permission enables editing and comment moderation for a non-admin.
- Create-only permission allows Redmine's actual AJAX upload endpoint and article creation with an upload token.
- Downloaded attachment bytes match the original, including Unicode; hidden article attachments cannot be downloaded anonymously.
- Create-only permission cannot edit existing attachments; edit permission can edit their metadata.
- Invalid attachment tokens return validation errors instead of a server error.
- Deleting an article removes dependent ratings and views.

### Migration coverage

The migration test creates randomly named `kb_migration_*` databases, then removes only those databases. It validates:

1. Every plugin migration from an empty schema.
2. Installation with pre-existing legacy `tags`/`taggings` and a foreign `Issue` tagging.
3. Additive creation of modern tag fields/counter cache without losing the foreign tagging.
4. Re-running the upgrade without recreating data.
5. IPv6 address capacity.
6. Migration down to zero, preserving shared tag tables and another plugin's assignment.

The original installation conflict with the existing Redmine Tags tables was reproduced and corrected before the request tests were run.

## Integrated browser checks

Performed through the actual Redmine forms and links at the local development instance:

| Workflow | Result |
| --- | --- |
| Admin sign-in | Passed after restoring the user-confirmed local `admin/admin` development login. |
| Create a root category and a child category | Passed; breadcrumb and category tree show the hierarchy. |
| Edit the child category description | Passed; saved text survives navigation. |
| Create an article with Unicode text and two comma-separated tags | Passed. |
| Preview a new article | Passed; formatted content renders. |
| Upload two text attachments before creating the article | Passed; both attach to the saved article. |
| Edit an article and preview all four wiki macros | Passed after correcting the edit-form method override in preview requests. |
| Save the article update | Passed; tag delimiters and existing attachments are preserved. |
| Submit a four-star rating | Passed; the page displays an average of 4/5 and one vote. |
| Add a comment containing German umlauts | Passed; the comment is visible after redirect. |
| Download an individual attachment | Passed; SHA-256 matches the original upload. |
| Download all attachments as ZIP | Passed; ZIP contains both files with the expected byte sizes. |
| Edit an attachment description | Passed; saving returns to the article and displays the description. |
| Follow a Unicode tag link | Passed; matching article is listed. |
| Review all four overview sections and the tag cloud | Passed, including the narrow browser panel after correcting category-selector wrapping and article-list floats. |
| Select a category in the overview dropdown | Passed; opens the selected child category. |
| Search globally for the article title | Passed; one matching knowledgebase result opens the article URL. |
| Open plugin configuration and save unchanged settings | Passed; Redmine confirms the update. |

Browser test data is retained locally for inspection: the `Knowledgebase – Redmine 6.1 Browserprüfung` root category, its `Installation und Bedienung` child, and `Redmine 6.1 – geprüfter Wissensartikel` with its attachments/comment/rating. It is not part of the Git repository. Destructive operations and authorization failures were exercised through the transactional request suite rather than removing this demonstration data.

## Scope and behavior notes

- The knowledge base remains global. A role permission obtained in one project membership applies globally, matching the original design.
- Aggregate ratings accept more than one vote per authorized user. View deduplication uses user **or** IP, so a shared IP can combine views.
- English and German were checked for rendered text; other locales were checked for valid YAML, not for translation completeness.
- Reload testing isolates this plugin's initialization. It does not certify other installed plugins' reload hooks.
- Fresh installation and a legacy shared-tag schema were tested. An upgrade of every historical fork, or an external production database, was not available for validation.
- Migration down preserves shared tag tables but does not clean up Redmine's attachment files or polymorphic comment/attachment records. Back up data and remove unwanted articles through Redmine before uninstalling; details are in the README.
- Rails emits its existing timezone-conversion deprecation warning; the local mail monitoring plugin also reports disabled email delivery. Neither caused a Knowledgebase test failure.
