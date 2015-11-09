# Changelog

Non-trivial changes will be documented here. 
This project adheres to [Semantic Versioning](http://semver.org/) 
and [keeps a change log](http://keepachangelog.com/) (you're reading it!).

## Unreleased

### Changed
 - Two methods for Composer: `#query` to compose an ActiveRecord query and `#conditions` to compose an array of Arel conditions.
 - Hash cleaner applied within Composer methods.
 - Graph traversal results are now cached.

### Fixed
 - fixed a number of typos in SPEC and README.

## Release [v0.3.1-pre](https://github.com/cofiem/clearly-query/releases/tag/v0.3.1-pre) (2015-11-01)

### Added
 - new DFS graph traversal for calculating joins between tables
 - additional tests for Composer

### Changed
 - composer and definition functionality redistributed to be more obvious and have simpler methods

## Release [v0.2.0-pre](https://github.com/cofiem/clearly-query/releases/tag/0.2.0) (2015-10-27)

### Added

 - Transported hash filter modules and classes from [baw-server](https://github.com/QutBioacoustics/baw-server)
  - Created change log

## Change log categories

### Added
new features

### Changed
changes in existing functionality

### Deprecated
once-stable features removed in upcoming releases

### Removed
deprecated features removed in this release

### Fixed
bug fixes

### Security
vulnerabilities or other problems that should be highlighted
