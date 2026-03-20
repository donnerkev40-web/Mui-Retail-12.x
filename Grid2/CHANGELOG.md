# Grid2

## [3.1.12](https://github.com/michaelnpsp/Grid2/tree/3.1.12) (2026-03-14)
[Full Changelog](https://github.com/michaelnpsp/Grid2/compare/3.1.7...3.1.12) [Previous Releases](https://github.com/michaelnpsp/Grid2/releases)

- Removed strict filter option in group of buffs statuses.  
    Removed some unused code in auras statuses.  
    Removed old interface tags in toc file.  
- Fixes in dispellablebyme debuffs status.  
- Workaround to blizzard bug: Aura filters are returning all auras when the unit is not visible.  
- Now default stack count for statuses is zero.  
- Now defensives debuffs are not displayed if the unit is not visible (CF #1442)  
- Small optimizations on multibar update methods.  
- Merge branch 'feature-multibar-refactor' of https://github.com/michaelnpsp/grid2 into feature-multibar-refactor  
- Bar and Multibars: Now if the configured bar opacity is zero, the bar will use the opacity provided by the active color status.  
- Bar and Multibars: Now if the configured bar opacity is zero, the bar will use the opacity provided by the active color status.2222222222222222  
- Now the status color opacity is used for bars and multibars if the value is not secret and the status opacity value is lower than the configured bar opacity (pre-midnight behaviour if the opacity is not secret).  
- Bug Fix: multibar background anchored to the main bar was not anchored correctly.  
- Multibar indicator: now the same status can be used in several bars.  
- Merge branch 'main' into feature-multibar-refactor  
- Added extra function to support displaying the same status on different bars.  
