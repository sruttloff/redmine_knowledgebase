# Knowledgebase for Redmine 6.1

Knowledgebase adds a central, searchable knowledge base to Redmine. Organize articles in nested categories, format content with Redmine's wiki editor, attach files, collect comments and ratings, and link knowledge from issues and wiki pages.

This fork is maintained for Redmine 6.1 by **[SaaS-Secure.com, S. Ruttloff](https://www.saas-secure.com/)**. It is based on [Alex Bevilacqua's original Knowledgebase](https://github.com/alexbevi/redmine_knowledgebase) and the [Arkhitech fork](https://github.com/arkhitech/redmine_knowledgebase).

**Version: 3.0.0.** Validated with **Redmine 6.1.2-stable**, **Rails 7.2.3**, **Ruby 3.3.7**, **MySQL 8.4.11**, `acts-as-taggable-on` **13.0.0**, and `awesome_nested_set` **3.9.0**. See the [validation report](doc/REDMINE_6_1_VALIDATION.md) for tested workflows and scope, and the [changelog](CHANGELOG.md) for release notes. Other Redmine versions and database adapters have not been validated.

## Features

- Global knowledge base, accessible from Redmine's top menu.
- Nested categories with descriptions, breadcrumbs, category navigation, alphabetical sorting and article counts.
- Articles with a title, summary, formatted content, author and updater information.
- Newest, recently updated, most viewed and top rated article summaries.
- Comma-separated tags, tag cloud and tag filtering, including names containing spaces and Unicode.
- Redmine attachment uploads, individual downloads, ZIP downloads, and editing file names/descriptions.
- Article comments and moderation, with a Redmine wiki toolbar.
- Ratings from one to five and an average/count display.
- View counts deduplicated by user or IP address, including IPv6.
- Global Redmine search and four wiki macros for article/category links.
- Separate read, authoring, rating/commenting, moderation and category management permissions.
- English and German interface text; existing community translations are preserved.

## Requirements

- Redmine **6.1.x** and the Ruby/Rails versions supported by that release.
- The gems declared in this plugin's `Gemfile`: `acts-as-taggable-on` and `awesome_nested_set`.
- A database and file backup before installing or upgrading.

Version 3.0.0 targets Redmine 6.1 and replaces the old `redmine_acts_as_taggable_on` Git dependency and dynamically generated rating/viewing models. The plugin does not load its historical `acts_as_rated` and `acts_as_viewed` libraries or the bundled legacy jQuery rating scripts.

## Installation

Check out the published release in Redmine's plugin directory. The directory must be named exactly `redmine_knowledgebase`:

```sh
cd /path/to/redmine/plugins
git clone --branch v3.0.0 https://github.com/sruttloff/redmine_knowledgebase.git redmine_knowledgebase
cd /path/to/redmine
bundle install
bundle exec rake redmine:plugins:migrate NAME=redmine_knowledgebase RAILS_ENV=production
```

If your deployment uses precompiled assets, rebuild them:

```sh
bundle exec rake assets:precompile RAILS_ENV=production
```

Restart the Redmine application server. The restart command depends on your deployment (Puma, Passenger, systemd or Docker).

### Upgrade

1. Back up the database, uploaded files and plugin directory.
2. Fetch the release and update the plugin checkout to `v3.0.0`.
3. Run `bundle install`, the plugin migration, and asset compilation as shown above.
4. Restart Redmine and review the plugin settings and role permissions.

Existing categories, articles, comments, ratings, views and tag assignments retain their table names and identifiers. The upgrade adds missing modern tag schema and expands stored IP addresses to support IPv6. It does not recreate the existing knowledge base.

### Shared tags and other plugins

Knowledgebase shares the standard `tags` and `taggings` tables used by `acts-as-taggable-on`. The migration accepts existing tables, preserves other plugins' assignments, adds missing fields and rebuilds a missing counter cache. It has been checked alongside the installed Redmine Tags plugin.

Do not remove shared tag tables while another plugin uses them. Knowledgebase's uninstall migration removes only `KbArticle` tag assignments and preserves the shared tables. Other plugins' own uninstall migrations may behave differently.

## Setup and permissions

Under **Administration → Plugins → Knowledgebase → Configure**, review these options:

| Setting | Default | Purpose |
| --- | --- | --- |
| Allow anonymous access | Enabled | Allows article, category and tag browsing without a plugin read permission. Redmine's site-wide login requirement still applies. |
| Sort category tree alphabetically | Enabled | Sorts the category tree by title. |
| Show category totals | Enabled | Shows direct article counts beside category titles. |
| Summary page article limit | 5 | Maximum articles per overview section; the effective value is constrained to 1–100. |

Under **Administration → Roles and permissions**, grant the permissions users need:

| Permission | Purpose |
| --- | --- |
| View articles (`view_articles`) | Read articles, categories and tags when anonymous access is disabled. |
| Comment on and rate articles (`comment_and_rate_articles`) | Add comments and submit a rating. |
| Create articles (`create_articles`) | Create articles, upload their files and preview content. |
| Edit articles (`edit_articles`) | Edit articles and their attachments, upload files and preview content. |
| Manage articles (`manage_articles`) | Create, edit and delete articles; rate, comment and moderate comments. |
| Manage article comments (`manage_articles_comments`) | Delete article comments. |
| Create article categories (`create_article_categories`) | Create categories. |
| Manage article categories (`manage_article_categories`) | Create, edit, move and delete categories. |

The knowledge base is **global**, rather than separated into project knowledge bases. Redmine's global authorization checks the roles the user has in their project memberships, plus the built-in Non member role. Permissions granted through one membership apply to the global knowledge base. Administrators can manage all articles and categories. Category and article creation are separate permissions: create a category before creating an article.

Anonymous access allows reading only. All write operations require a logged-in user with the relevant permission. Attachment read/edit/delete permissions follow article access; merely being logged in does not allow deleting an attachment.

## Usage

1. Open **Knowledgebase** in the top menu and choose **New Category**.
2. Leave **Root Category** selected for a top-level category. To nest a category, clear it and select a parent. A category cannot become its own descendant.
3. Open a category, choose **New Article**, and enter its title, summary and content. The editor uses the wiki formatting configured in Redmine, such as CommonMark Markdown or Textile.
4. Add comma-separated tags and optional files. The maximum upload size follows Redmine's attachment settings.
5. Use **Preview** to inspect the content before creating or updating the article.
6. Open the article to read its content, download files, submit a rating or add a comment. Editing preserves separate tags and existing attachments.
7. Use the overview, category selector, tag cloud or Redmine's global search to find articles.

An article can receive multiple votes from the same authorized user, matching the original plugin's aggregate rating behavior. Ratings are not a one-vote-per-user poll. View counts deduplicate by user **or** IP, so people sharing an IP address may count as a single view.

Deleting an article removes its comments, attachments, ratings, views and tag assignments. A category cannot be deleted while it or any descendant contains an article. Deleting an empty category removes its empty descendants.

### Wiki macros

Use these macros in Redmine wiki-formatted text, replacing the IDs with actual article/category IDs:

| Macro | Output |
| --- | --- |
| `{{kb(123)}}` | Article link, such as `KB#123`. |
| `{{article_id(123)}}` | Same article link format as `kb`. |
| `{{article(123)}}` | Article link including its title. |
| `{{category(45)}}` | Category link including its title. |

Macros respect knowledge base visibility. Invalid or inaccessible IDs produce Redmine's normal macro error rather than revealing hidden titles.

### Localization

Menus, article/category forms, comments, ratings, permissions and plugin settings are available in English and German. Other community locale files remain available. User-entered titles, content and tags are not translated.

## Changes for Redmine 6.1

- Updated labelled forms, routes, preview requests, strong parameters and attachment handling for Rails 7.2.
- Removed the runtime dependency on the old Git-based tag migration wrapper; modern shared tag tables are supported.
- Introduced explicit, reloadable `KbRating` and `KbViewing` models using existing tables.
- Replaced obsolete jQuery rating widgets with a standard authenticated form.
- Fixed preview when editing an article, comment validation, missing-record responses, search result URLs, and attachment container URLs.
- Preserved tag delimiters in edit forms and restored all four overview sections.
- Added validation for rating bounds, category cycles and non-empty subtrees.
- Enforced write permissions and attachment access; escaped summaries and macro link text.
- Kept macro and search registration working across Rails reloads.
- Corrected German text and added translated permissions and plural vote labels.

## Validation and development

Use an already migrated development/test installation:

```sh
bundle exec rake zeitwerk:check
bundle exec rails runner plugins/redmine_knowledgebase/test/compatibility_smoke.rb
bundle exec rails runner plugins/redmine_knowledgebase/test/reload_smoke.rb
bundle exec ruby plugins/redmine_knowledgebase/test/localization_smoke.rb
```

The compatibility check uses actual Rails requests, temporary accounts with generated passwords, and a database transaction. Temporary database records are rolled back; existing accounts and passwords are not changed. The reload check isolates this plugin's initialization because other installed plugins may have unrelated reload issues.

The standalone MySQL migration check requires a local administrative connection permitted to create and drop temporary databases:

```sh
KNOWLEDGEBASE_MIGRATION_DATABASE_URL='mysql2://USER:PASSWORD@HOST/mysql' \
  bundle exec ruby plugins/redmine_knowledgebase/test/migration_smoke.rb
```

It creates and removes only databases named `kb_migration_<random hex>`. It checks fresh installation, legacy shared tags, repeated upgrade, IPv6 and preservation of foreign tag assignments on uninstall. Never use production credentials for development checks.

To refresh and sort community translations, run from the plugin directory:

```sh
ruby bin/refresh_localizations.rb
```

This utility rewrites the locale files, fills missing keys from English and uses Ruby's standard YAML library.

## Uninstall

Back up the database and uploaded files first. Removing the plugin's data is destructive:

```sh
bundle exec rake redmine:plugins:migrate NAME=redmine_knowledgebase VERSION=0 RAILS_ENV=production
```

Then remove the plugin directory, run `bundle install`, rebuild assets if needed, and restart Redmine. The migration drops knowledge base tables and preserves shared tag tables; it does not clean up attachment files or polymorphic comment/attachment records. For a clean removal, delete unwanted articles through Redmine before migrating down, or retain them in your backup for recovery.

## More plugins from SaaS-Secure.com

- **[Redmine UX Toolkit](https://www.saas-secure.com/online-services/redmine-ux-toolkit.html)** – Interface, dashboards, checklists, templates, reminders and administration tools.
- **[SCM Creator for Redmine](https://www.saas-secure.com/online-services/redmine-scm.html)** – Repository management for Git, Subversion, Mercurial, Bazaar and GitHub.

These optional plugins are not required by Knowledgebase. For hosting and other services, visit **[www.saas-secure.com](https://www.saas-secure.com/)**.

## Support and credits

Report problems through **[GitHub Issues](https://github.com/sruttloff/redmine_knowledgebase/issues)**, including your Redmine, Ruby, Rails and database versions and the steps to reproduce the issue.

- Original author: [Alex Bevilacqua](https://github.com/alexbevi).
- Previous Redmine adaptations: [Arkhitech](https://github.com/arkhitech/redmine_knowledgebase) and community contributors.
- Redmine 6.1 adaptation and maintenance: [SaaS-Secure.com, S. Ruttloff](https://www.saas-secure.com/).
- Full contributor and translator list: [AUTHORS](AUTHORS).

## License

Knowledgebase is released under the **MIT License**. The original **Copyright (c) 2010–2013 Alex Bevilacqua** notice is preserved; see [LICENSE](LICENSE). Historical bundled libraries retain their respective copyright and license notices.
