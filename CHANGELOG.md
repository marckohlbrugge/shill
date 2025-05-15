## [Unreleased]

## [0.2.1] - 2025-05-15

- Change: `fetch_projects` now always raises `Shill::Error` on failure instead of silently returning `nil`. This prevents `Shill.projects` from ever returning `nil`.

## [0.2.0] - 2025-05-15

- Feature: `shill_projects` and `shill_random_project` view helpers auto-load in Rails apps.

## [0.1.1] - 2025-05-15

- Fix: Replace example URLs

## [0.1.0] - 2025-05-15

- Initial release
