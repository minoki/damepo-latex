import Control.Applicative
import Numeric
import Control.Arrow
import Data.Char (ord,chr,toUpper)
import Data.List
import System.Environment
import System.Exit
import System.IO

leftpadWith0 :: Int -> String -> String
leftpadWith0 n s | length s < n = leftpadWith0 n ('0':s)
                 | otherwise = s

data UnicodeEscStyle = ECMAScriptStyle | PCREStyle | PythonStyle deriving Eq

showHEX = (map toUpper .) . showHex

showUnicodeEsc :: UnicodeEscStyle -> Int -> String
showUnicodeEsc ECMAScriptStyle c | chr c `elem` "-]\\" = ['\\', chr c]
                                 | c < 0x80 = [chr c]
                              -- | c < 0x10000 && not (0xD800 <= c && c <= 0xDFFF) = [chr c] -- "\\u" ++ leftpadWith0 4 (showHEX c "")
                                 | c < 0x10000 = "\\\\u" ++ leftpadWith0 4 (showHEX c "")
                                 | otherwise = "\\\\u{" ++ showHEX c "}"
showUnicodeEsc PCREStyle c | chr c `elem` "-]\\" = ['\\', chr c]
                           | c < 0x80 = [chr c]
                           | otherwise = "\\\\x{" ++ showHEX c "}"
showUnicodeEsc PythonStyle c | chr c `elem` "-]\\" = ['\\', chr c]
                             | c < 0x80 = [chr c]
                             | c < 0x10000 = "\\\\u" ++ leftpadWith0 4 (showHEX c "")
                             | otherwise = "\\\\U" ++ leftpadWith0 8 (showHEX c "")

showUnicodeEscRange :: UnicodeEscStyle -> Int -> Int -> String
showUnicodeEscRange style x y | x == y = showUnicodeEsc style x
                              | otherwise = showUnicodeEsc style x ++ "-" ++ showUnicodeEsc style y

buildRangeRx :: UnicodeEscStyle -> [(Int,Int)] -> String
buildRangeRx _ [] = ""
buildRangeRx style [(x,y)] | x == y = showUnicodeEsc style x
buildRangeRx style xs = "[" ++ concatMap (uncurry (showUnicodeEscRange style)) xs ++ "]"

setToRanges :: (Enum a, Eq a) => [a] -> [(a,a)]
setToRanges [] = []
setToRanges [c] = [(c,c)]
setToRanges (x:xs) = loop x x xs
  where loop x y [] = [(x,y)]
        loop x y (z:zs) | z == succ y = loop x z zs
                        | otherwise = (x,y) : loop z z zs

parseUnicodeDataLine :: String -> Maybe (Int,String,String)
parseUnicodeDataLine s
  | (codepoint_s,';':xs) <- span (/= ';') s
  , (description,';':ys) <- span (/= ';') xs
  , (cat,';':_) <- span (/= ';') ys
  , [(codepoint,"")] <- readHex codepoint_s = Just (codepoint,description,cat)
  | otherwise = Nothing

parseUnicodeData :: [String] -> [(Int,String)]
parseUnicodeData [] = []
parseUnicodeData (x:xs) | Just (xp,xd,xc) <- parseUnicodeDataLine x
                        , isSuffixOf ", First>" xd
                        , y:ys <- xs
                        , Just (yp,yd,yc) <- parseUnicodeDataLine y
                        , isSuffixOf ", Last>" yd
                        = if xc /= yc
                          then error "General Category mismatch"
                          else [(cp,xc) | cp <- [xp..yp]]++parseUnicodeData ys
                        | Just (xp,xd,xc) <- parseUnicodeDataLine x
                        = (xp,xc):parseUnicodeData xs
                        | otherwise = error "failed to parse"

encodeUtf16 :: Int -> Either Int (Int,Int)
encodeUtf16 x | x < 0x10000 = Left x
              | otherwise = let xm = x - 0x10000
                                (hi',lo') = xm `divMod` 0x400
                            in Right (0xD800 + hi', 0xDC00 + lo')

partitionEither :: [Either a b] -> ([a],[b])
--partitionEither [] = ([],[])
--partitionEither (Left x:xs) = first (x:) $ partitionEither xs
--partitionEither (Right y:xs) = second (y:) $ partitionEither xs
partitionEither = foldr (either (first . (:)) (second . (:))) ([],[])

eqFst :: Eq a => (a,b) -> (a,b) -> Bool
eqFst x y = fst x == fst y

eqSnd :: Eq b => (a,b) -> (a,b) -> Bool
eqSnd x y = snd x == snd y

-- groupByFst [(1,2),(1,3),(1,5),(2,3),(3,1),(3,7)]
-- ->[(1,[2,3,5]),(2,[3]),(3,[1,7])]
groupByFst :: Eq a => [(a,b)] -> [(a,[b])]
groupByFst [] = []
groupByFst ((s,t):xs) | (s',t'):_ <- xs
                      , s == s' = let (u,v):ys = groupByFst xs
                                  in (u,t:v):ys
                      | otherwise = (s,[t]):groupByFst xs

groupBySnd :: Eq b => [(a,b)] -> [([a],b)]
groupBySnd = map swap . groupByFst . map swap
  where swap (x,y) = (y,x)

isLetter = (== 'L') . head

compareByFst :: (Ord a, Ord b) => (a,b) -> (a,b) -> Ordering
compareByFst (x,y) (x',y') = case compare x x' of
  EQ -> compare y y'
  c -> c

compareBySnd :: (Ord a, Ord b) => (a,b) -> (a,b) -> Ordering
compareBySnd (x,y) (x',y') = case compare y y' of
  EQ -> compare x x'
  c -> c

data UnicodeEncodingMode = UTF32Mode | SurrogatePairsMode deriving Eq
usage :: IO ()
usage = do name <- getProgName
           hPutStrLn stderr $ "Usage: " ++ name ++ " [option] category"
           hPutStrLn stderr "Options:"
           hPutStrLn stderr "\t--pcre: PCRE style (\\x{HHHH} for Unicode escape)"
           hPutStrLn stderr "\t--es: ECMAScript style (\\uHHHH or \\u{HHHHH} for Unicode escape)"
           hPutStrLn stderr "\t--python: Python style (\\uHHHH or \\UHHHHHHHH for Unicode escape)"
           hPutStrLn stderr "\t--surrogate-pairs: Use surrogate pairs to represent code points > U+FFFF (for ECMAScript 5)"
           hPutStrLn stderr "\t--utf32: Assume the processor can natively handle code points > U+FFFF (for ECMAScript 6 with unicode flag)"
           hPutStrLn stderr "Category: Prefix of short General Category"
parseArgs :: [String] -> IO (UnicodeEscStyle,UnicodeEncodingMode,String)
parseArgs s = loop s (Nothing,Nothing,Nothing)
  where loop :: [String] -> (Maybe UnicodeEscStyle,Maybe UnicodeEncodingMode,Maybe String) -> IO (UnicodeEscStyle,UnicodeEncodingMode,String)
        loop [] (_,_,Nothing) = usage >> exitFailure
        loop [] (x,y,Just catPrefix) = let style = maybe ECMAScriptStyle id x
                                           defaultMode | style == ECMAScriptStyle = SurrogatePairsMode
                                                       | otherwise = UTF32Mode
                                       in return (style,maybe defaultMode id y,catPrefix)
        loop ("--es":ss) (x,y,z) | x == Nothing = loop ss (Just ECMAScriptStyle,y,z)
                                 | otherwise = errMsg "Escape sequence style already set."
        loop ("--pcre":ss) (x,y,z) | x == Nothing = loop ss (Just PCREStyle,y,z)
                                   | otherwise = errMsg "Escape sequence style already set."
        loop ("--python":ss) (x,y,z) | x == Nothing = loop ss (Just PythonStyle,y,z)
                                     | otherwise = errMsg "Escape sequence style already set."
        loop ("--surrogate-pairs":ss) (x,y,z) | y == Nothing = loop ss (x,Just SurrogatePairsMode,z)
                                              | otherwise = errMsg "Encoding mode is already set."
        loop ("--utf32":ss) (x,y,z) | y == Nothing = loop ss (x,Just UTF32Mode,z)
                                    | otherwise = errMsg "Encoding mode is already set."
        loop (s:ss) (x,y,z) | z == Nothing = loop ss (x,y,Just s)
                            | otherwise = errMsg "Unicode General Category is already set."
        errMsg msg = do hPutStrLn stderr $ "Error: " ++ msg
                        usage
                        exitFailure

main = do (style,mode,catPrefix) <- getArgs >>= parseArgs
          l <- lines <$> readFile "UnicodeData.txt"
          let codepoints = parseUnicodeData l
              letters = map fst $ filter (isPrefixOf catPrefix . snd) codepoints
              (bmp,surrogates) = partitionEither $ map encodeUtf16 letters
              bmprx = buildRangeRx style $ setToRanges bmp
          let surrogateGroups :: [(Int,[(Int,Int)])]
              surrogateGroups = map (second setToRanges) $ groupByFst surrogates
              surrogateGroups2 :: [([(Int,Int)],[(Int,Int)])]
              surrogateGroups2 = sortBy compareByFst $ map (first setToRanges) $ groupBySnd $ sortBy compareBySnd surrogateGroups
              surrogatesRx :: [String]
              surrogatesRx = map (uncurry (++) . (buildRangeRx style *** buildRangeRx style)) surrogateGroups2
          if mode == SurrogatePairsMode
          then putStrLn (concat $ intersperse "|" $ bmprx:surrogatesRx)
          else putStrLn (buildRangeRx style $ setToRanges letters)
