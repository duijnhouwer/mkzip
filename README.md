# mkzip
Matlab class to losslessly compress and uncompress numerical matrices and strings in memory
 
Example:
```matlab
  d = randi(8,1000,1000); % generate some data
  M = mkzip(d) % compress d in mkzip object M 
  d = M.unzip; % return uncompressed d 
  r = M.ratio % 0 means no compression, 1 means fully compressed
```
This is a class wrapper for Michael Kleder dzip/dunzip functions.
The main advantage of making this a class is that it is impossible
to forget that a certain array is zipped and end up doing
calculations on it as if it is the actual data, which could be
disastrous. It also provides some extra functionality (e.g., ratio)
and as a class only one M-file is needed instead of one for dzip 
and one for dunzip.
