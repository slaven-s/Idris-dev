module Main where

import Idris.Core.TT
import Idris.AbsSyntax
import Idris.ElabDecls
import Idris.REPL

import IRTS.Compiler
import IRTS.CodegenJavaScript

import System.Environment
import System.Exit

import Paths_idris

data Opts = Opts { really :: Bool
                 , inputs :: [FilePath]
                 , output :: FilePath
                 }

showUsage = do putStrLn "A code generator which is intended to be called by the compiler, not by a user."
               putStrLn "To call the code generator manually, pass the --yes-really option.\n"
               putStrLn "Usage: idris-codegen-c [--yes-really] <ibc-files> [-o <output-file>]"
               exitWith ExitSuccess

getOpts :: IO Opts
getOpts = do xs <- getArgs
             return $ process (Opts False [] "main.js") xs
  where
    process opts ("--yes-really":xs) = process (opts { really = True }) xs
    process opts ("-o":o:xs) = process (opts { output = o }) xs
    process opts (x:xs) = process (opts { inputs = x:inputs opts }) xs
    process opts [] = opts

jsMain :: Opts -> Idris ()
jsMain opts = do elabPrims
                 loadInputs (inputs opts) Nothing
                 mainProg <- elabMain
                 ir <- compile (Via "node") (output opts) (Just mainProg)
                 runIO $ codegenNode ir

main :: IO ()
main = do opts <- getOpts
          if (null (inputs opts))
             then showUsage
             else if (not $ really opts)
                     then do putStrLn "This code generator is intended to be called by the Idris compiler. \
                                      \Please pass Idris the '--codegen' flag to choose a backend."
                             exitWith ExitSuccess
                     else runMain (jsMain opts)
