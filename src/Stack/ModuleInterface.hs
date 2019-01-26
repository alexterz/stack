module Stack.ModuleInterface
    ( Interface(..)
    , FastString(..)
    , List(..)
    , Dictionary(..)
    , Module(..)
    , Usage(..)
    , Dependencies(..)
    , getInterface
    ) where

import           Control.Monad   (replicateM, replicateM_, when)
import           Data.Binary
import           Data.Binary.Get (bytesRead, getInt64be, getWord32be,
                                  getWord64be, getWord8, lookAhead, skip)
import           Data.Bool       (bool)
import           Data.Char       (chr)
import           Data.Functor    (void, ($>))
import           Data.List       (find)
import           Data.Maybe      (catMaybes)
import           Data.Semigroup  ((<>))
import qualified Data.Vector     as V
import           Foreign         (sizeOf)
import           Numeric         (showHex)

type IsBoot = Bool

type ModuleName = FastString

newtype List a = List
    { unList :: [a]
    } deriving (Show)

newtype FastString = FastString
    { unFastString :: String
    } deriving (Show)

newtype Dictionary = Dictionary
    { unDictionary :: V.Vector FastString
    } deriving (Show)

newtype Module = Module
    { unModule :: ModuleName
    } deriving (Show)

newtype Usage = Usage
    { unUsage :: FilePath
    } deriving (Show)

data Dependencies = Dependencies
    { dmods    :: List (ModuleName, IsBoot)
    , dpkgs    :: List (ModuleName, Bool)
    , dorphs   :: List Module
    , dfinsts  :: List Module
    , dplugins :: List ModuleName
    } deriving (Show)

data Interface = Interface
    { deps  :: Dependencies
    , usage :: List Usage
    } deriving (Show)

-- | Read a block prefixed with its length
withBlockPrefix :: Get a -> Get a
withBlockPrefix f = getWord32be *> f

getBool :: Get Bool
getBool = toEnum . fromIntegral <$> getWord8

getString :: Get String
getString = fmap (chr . fromIntegral) . unList <$> getList getWord32be

getMaybe :: Get a -> Get (Maybe a)
getMaybe f = bool (pure Nothing) (Just <$> f) =<< getBool

getList :: Get a -> Get (List a)
getList f = do
    i <- getWord8
    l <-
        if i == 0xff
            then getWord32be
            else pure (fromIntegral i :: Word32)
    List <$> replicateM (fromIntegral l) f

getTuple :: Get a -> Get b -> Get (a, b)
getTuple f g = (,) <$> f <*> g

getFastString :: Get FastString
getFastString = do
    size <- getInt64be
    FastString . fmap (chr . fromIntegral) <$>
        replicateM (fromIntegral size) getWord8

getDictionary :: Int -> Get Dictionary
getDictionary ptr = do
    offset <- bytesRead
    skip $ ptr - fromIntegral offset
    size <- fromIntegral <$> getInt64be
    Dictionary <$> V.replicateM size getFastString

getCachedFS :: Dictionary -> Get FastString
getCachedFS d = go =<< getWord32be
  where
    go i =
        case unDictionary d V.!? fromIntegral i of
            Just fs -> pure fs
            Nothing -> fail $ "Invalid dictionary index: " <> show i

getFP :: Get ()
getFP = void $ getWord64be *> getWord64be

getInterface721 :: Dictionary -> Get Interface
getInterface721 d = do
    void getModule
    void getBool
    replicateM_ 2 getFP
    void getBool
    void getBool
    Interface <$> getDependencies <*> getUsage
  where
    getModule = getCachedFS d *> (Module <$> getCachedFS d)
    getDependencies =
        withBlockPrefix $
        Dependencies <$> getList (getTuple (getCachedFS d) getBool) <*>
        getList (getTuple (getCachedFS d) getBool) <*>
        getList getModule <*>
        getList getModule <*>
        pure (List [])
    getUsage = withBlockPrefix $ List . catMaybes . unList <$> getList go
      where
        go :: Get (Maybe Usage)
        go = do
            usageType <- getWord8
            case usageType of
                0 -> getModule *> getFP *> getBool $> Nothing
                1 ->
                    getCachedFS d *> getFP *> getMaybe getFP *>
                    getList (getTuple (getWord8 *> getCachedFS d) getFP) *>
                    getBool $> Nothing
                _ -> fail $ "Invalid usageType: " <> show usageType

getInterface741 :: Dictionary -> Get Interface
getInterface741 d = do
    void getModule
    void getBool
    replicateM_ 3 getFP
    void getBool
    void getBool
    Interface <$> getDependencies <*> getUsage
  where
    getModule = getCachedFS d *> (Module <$> getCachedFS d)
    getDependencies =
        withBlockPrefix $
        Dependencies <$> getList (getTuple (getCachedFS d) getBool) <*>
        getList (getTuple (getCachedFS d) getBool) <*>
        getList getModule <*>
        getList getModule <*>
        pure (List [])
    getUsage = withBlockPrefix $ List . catMaybes . unList <$> getList go
      where
        go :: Get (Maybe Usage)
        go = do
            usageType <- getWord8
            case usageType of
                0 -> getModule *> getFP *> getBool $> Nothing
                1 ->
                    getCachedFS d *> getFP *> getMaybe getFP *>
                    getList (getTuple (getWord8 *> getCachedFS d) getFP) *>
                    getBool $> Nothing
                2 -> Just . Usage <$> getString <* getWord64be <* getWord64be
                _ -> fail $ "Invalid usageType: " <> show usageType

getInterface761 :: Dictionary -> Get Interface
getInterface761 d = do
    void getModule
    void getBool
    replicateM_ 3 getFP
    void getBool
    void getBool
    Interface <$> getDependencies <*> getUsage
  where
    getModule = getCachedFS d *> (Module <$> getCachedFS d)
    getDependencies =
        withBlockPrefix $
        Dependencies <$> getList (getTuple (getCachedFS d) getBool) <*>
        getList (getTuple (getCachedFS d) getBool) <*>
        getList getModule <*>
        getList getModule <*>
        pure (List [])
    getUsage = withBlockPrefix $ List . catMaybes . unList <$> getList go
      where
        go :: Get (Maybe Usage)
        go = do
            usageType <- getWord8
            case usageType of
                0 -> getModule *> getFP *> getBool $> Nothing
                1 ->
                    getCachedFS d *> getFP *> getMaybe getFP *>
                    getList (getTuple (getWord8 *> getCachedFS d) getFP) *>
                    getBool $> Nothing
                2 -> Just . Usage <$> getString <* getWord64be <* getWord64be
                _ -> fail $ "Invalid usageType: " <> show usageType

getInterface781 :: Dictionary -> Get Interface
getInterface781 d = do
    void getModule
    void getBool
    replicateM_ 3 getFP
    void getBool
    void getBool
    Interface <$> getDependencies <*> getUsage
  where
    getModule = getCachedFS d *> (Module <$> getCachedFS d)
    getDependencies =
        withBlockPrefix $
        Dependencies <$> getList (getTuple (getCachedFS d) getBool) <*>
        getList (getTuple (getCachedFS d) getBool) <*>
        getList getModule <*>
        getList getModule <*>
        pure (List [])
    getUsage = withBlockPrefix $ List . catMaybes . unList <$> getList go
      where
        go :: Get (Maybe Usage)
        go = do
            usageType <- getWord8
            case usageType of
                0 -> getModule *> getFP *> getBool $> Nothing
                1 ->
                    getCachedFS d *> getFP *> getMaybe getFP *>
                    getList (getTuple (getWord8 *> getCachedFS d) getFP) *>
                    getBool $> Nothing
                2 -> Just . Usage <$> getString <* getFP
                _ -> fail $ "Invalid usageType: " <> show usageType

getInterface801 :: Dictionary -> Get Interface
getInterface801 d = do
    void getModule
    void getWord8
    replicateM_ 3 getFP
    void getBool
    void getBool
    Interface <$> getDependencies <*> getUsage
  where
    getModule = getCachedFS d *> (Module <$> getCachedFS d)
    getDependencies =
        withBlockPrefix $
        Dependencies <$> getList (getTuple (getCachedFS d) getBool) <*>
        getList (getTuple (getCachedFS d) getBool) <*>
        getList getModule <*>
        getList getModule <*>
        pure (List [])
    getUsage = withBlockPrefix $ List . catMaybes . unList <$> getList go
      where
        go :: Get (Maybe Usage)
        go = do
            usageType <- getWord8
            case usageType of
                0 -> getModule *> getFP *> getBool $> Nothing
                1 ->
                    getCachedFS d *> getFP *> getMaybe getFP *>
                    getList (getTuple (getWord8 *> getCachedFS d) getFP) *>
                    getBool $> Nothing
                2 -> Just . Usage <$> getString <* getFP
                3 -> getModule *> getFP $> Nothing
                _ -> fail $ "Invalid usageType: " <> show usageType

getInterface821 :: Dictionary -> Get Interface
getInterface821 d = do
    void getModule
    void $ getMaybe getModule
    void getWord8
    replicateM_ 3 getFP
    void getBool
    void getBool
    Interface <$> getDependencies <*> getUsage
  where
    getModule = do
        idType <- getWord8
        case idType of
            0 -> void $ getCachedFS d
            _ ->
                void $
                getCachedFS d *> getList (getTuple (getCachedFS d) getModule)
        Module <$> getCachedFS d
    getDependencies =
        withBlockPrefix $
        Dependencies <$> getList (getTuple (getCachedFS d) getBool) <*>
        getList (getTuple (getCachedFS d) getBool) <*>
        getList getModule <*>
        getList getModule <*>
        pure (List [])
    getUsage = withBlockPrefix $ List . catMaybes . unList <$> getList go
      where
        go :: Get (Maybe Usage)
        go = do
            usageType <- getWord8
            case usageType of
                0 -> getModule *> getFP *> getBool $> Nothing
                1 ->
                    getCachedFS d *> getFP *> getMaybe getFP *>
                    getList (getTuple (getWord8 *> getCachedFS d) getFP) *>
                    getBool $> Nothing
                2 -> Just . Usage <$> getString <* getFP
                3 -> getModule *> getFP $> Nothing
                _ -> fail $ "Invalid usageType: " <> show usageType

getInterface841 :: Dictionary -> Get Interface
getInterface841 d = do
    void getModule
    void $ getMaybe getModule
    void getWord8
    replicateM_ 5 getFP
    void getBool
    void getBool
    Interface <$> getDependencies <*> getUsage
  where
    getModule = do
        idType <- getWord8
        case idType of
            0 -> void $ getCachedFS d
            _ ->
                void $
                getCachedFS d *> getList (getTuple (getCachedFS d) getModule)
        Module <$> getCachedFS d
    getDependencies =
        withBlockPrefix $
        Dependencies <$> getList (getTuple (getCachedFS d) getBool) <*>
        getList (getTuple (getCachedFS d) getBool) <*>
        getList getModule <*>
        getList getModule <*>
        pure (List [])
    getUsage = withBlockPrefix $ List . catMaybes . unList <$> getList go
      where
        go :: Get (Maybe Usage)
        go = do
            usageType <- getWord8
            case usageType of
                0 -> getModule *> getFP *> getBool $> Nothing
                1 ->
                    getCachedFS d *> getFP *> getMaybe getFP *>
                    getList (getTuple (getWord8 *> getCachedFS d) getFP) *>
                    getBool $> Nothing
                2 -> Just . Usage <$> getString <* getFP
                3 -> getModule *> getFP $> Nothing
                _ -> fail $ "Invalid usageType: " <> show usageType

getInterface861 :: Dictionary -> Get Interface
getInterface861 d = do
    void getModule
    void $ getMaybe getModule
    void getWord8
    replicateM_ 6 getFP
    void getBool
    void getBool
    Interface <$> getDependencies <*> getUsage
  where
    getModule = do
        idType <- getWord8
        case idType of
            0 -> void $ getCachedFS d
            _ ->
                void $
                getCachedFS d *> getList (getTuple (getCachedFS d) getModule)
        Module <$> getCachedFS d
    getDependencies =
        withBlockPrefix $
        Dependencies <$> getList (getTuple (getCachedFS d) getBool) <*>
        getList (getTuple (getCachedFS d) getBool) <*>
        getList getModule <*>
        getList getModule <*>
        getList (getCachedFS d)
    getUsage = withBlockPrefix $ List . catMaybes . unList <$> getList go
      where
        go :: Get (Maybe Usage)
        go = do
            usageType <- getWord8
            case usageType of
                0 -> getModule *> getFP *> getBool $> Nothing
                1 ->
                    getCachedFS d *> getFP *> getMaybe getFP *>
                    getList (getTuple (getWord8 *> getCachedFS d) getFP) *>
                    getBool $> Nothing
                2 -> Just . Usage <$> getString <* getFP
                3 -> getModule *> getFP $> Nothing
                _ -> fail $ "Invalid usageType: " <> show usageType

getInterface :: Get Interface
getInterface = do
    magic <- getWord32be
    when (magic /= 0x1face64) (fail $ "Invalid magic: " <> showHex magic "")
  {-
    dummy value depending on the wORD_SIZE
    wORD_SIZE :: Int
    wORD_SIZE = (#const SIZEOF_HSINT)

    This was used to serialize pointers
  -}
    if sizeOf (undefined :: Int) == 4
        then void getWord32be
        else void getWord64be
  -- ghc version
    version <- getString
  -- way
    void getString
  -- dict_ptr
    dictPtr <- getWord32be
  -- dict
    dict <- lookAhead $ getDictionary $ fromIntegral dictPtr
  -- symtable_ptr
    void getWord32be
    let versions =
            [ ("8061", getInterface861)
            , ("8041", getInterface841)
            , ("8021", getInterface821)
            , ("8001", getInterface801)
            , ("7081", getInterface781)
            , ("7061", getInterface761)
            , ("7041", getInterface741)
            , ("7021", getInterface721)
            ]
    case snd <$> find ((version >=) . fst) versions of
        Just f  -> f dict
        Nothing -> fail $ "Unsupported version: " <> version
