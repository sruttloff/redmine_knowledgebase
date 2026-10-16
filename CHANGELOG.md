# Changelog

## 3.0.0 — 2026-10-16

This fork now targets Redmine 6.1.x. Tested on Redmine 6.1.2, Rails 7.2.3, Ruby 3.3.7 and MySQL 8.4.11.

- Update forms, article previews, routes, attachments, comments and global search for Redmine 6.1/Rails 7.2.
- Replace dynamically generated rating/viewing classes with reloadable models, preserving existing data.
- Support modern shared tag tables alongside Redmine Tags, including additive upgrades and safe tag-table preservation on uninstall.
- Fix tag delimiter preservation and preview requests when editing articles.
- Enforce write and attachment permissions, validate ratings, prevent category cycles, and protect non-empty subtrees.
- Restore newest and top rated overview sections; rank top rated articles by their average rating.
- Fix missing article/category responses, attachment container links and macro visibility.
- Keep wiki macros, models and search registration valid across Rails reloads.
- Support IPv6 view tracking; retain original aggregate rating and IP/user view-deduplication semantics.
- Improve German translations, permission labels, README, installation/upgrade instructions and release validation documentation.
- Add request/permission regression checks, repeated reload checks, and isolated MySQL installation/upgrade/uninstall checks.
- Remove the obsolete `ya2yaml` dependency from the translation maintenance utility.

## 2.3.0 and earlier

See the repository history and the original [Alex Bevilacqua](https://github.com/alexbevi/redmine_knowledgebase) and [Arkhitech](https://github.com/arkhitech/redmine_knowledgebase) repositories for previous releases and community contributions.
