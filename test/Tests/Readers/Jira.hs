{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{- |
   Module      : Tests.Readers.Jira
   Copyright   : © 2019-2020 Albert Krewinel
   License     : GNU GPL, version 2 or above

   Maintainer  : Albert Krewinkel <tarleb@zeitkraut.de>
   Stability   : alpha
   Portability : portable

Tests for the RST reader.
-}
module Tests.Readers.Jira (tests) where

import Prelude
import Data.Text (Text)
import Test.Tasty (TestTree, testGroup)
import Tests.Helpers (ToString, purely, test, (=?>))
import Text.Pandoc (def)
import Text.Pandoc.Readers.Jira (readJira)
import Text.Pandoc.Builder

jira :: Text -> Pandoc
jira = purely $ readJira def

infix 4 =:
(=:) :: ToString c
     => String -> (Text, c) -> TestTree
(=:) = test jira

tests :: [TestTree]
tests =
  [ testGroup "para"
    [ "Simple sentence" =:
      "Hello, World!" =?> para "Hello, World!"
    ]

  , testGroup "header"
    [ "header" =:
      "h1. Main\n" =?> header 1 "Main"
    ]

  , testGroup "list"
    [ "simple list" =:
      "* foo\n* bar\n" =?> bulletList [para "foo", para "bar"]

    , "list with minus as bullets" =:
      "- foo\n- bar\n" =?> bulletList [para "foo", para "bar"]

    , "ordered list / enumeration" =:
      "# first\n# second\n" =?> orderedList [para "first", para "second"]
    ]

  , testGroup "block quote"
    [ "simple block quote" =:
      "bq. _Don't_ quote me on this." =?>
      blockQuote (para $ emph "Don't" <> space <> "quote me on this.")
    ]

  , testGroup "table"
    [ "table without header" =:
      "| one | two |\n| three | four |\n" =?>
      simpleTable []
                  [ [para "one", para "two"]
                  , [para "three", para "four"]]

    , "table with header" =:
      "|| one || two ||\n| three | four |\n| five | six |\n" =?>
      simpleTable [para "one", para "two"]
                  [ [para "three", para "four"]
                  , [para "five", para "six"]]

    , "table with column header" =:
      "|| language | haskell | lua |\n|| type | static | dynamic |\n" =?>
      simpleTable []
                  [ [para "language", para "haskell", para "lua"]
                  , [para "type", para "static", para "dynamic"]]

    , "table after paragraph" =:
      "*tabletest*\n||Name|\n|Test|\n" =?>
      para (strong "tabletest") <>
      simpleTable [para "Name"] [[para "Test"]]
    ]

  , testGroup "inlines"
    [ "emphasis" =:
      "*quid pro quo*" =?>
      para (strong "quid pro quo")

    , "deleted" =:
      "-old-" =?>
      para (strikeout "old")

    , "monospaced" =:
      "{{this *is* monospace}}" =?>
      para (code "this is monospace")

    , "sub- and superscript" =:
      "HCO ~3~^-^" =?>
      para ("HCO " <> subscript "3" <> superscript "-")

    , "color" =:
      "This is {color:red}red{color}." =?>
      para ("This is " <> spanWith ("", [], [("color", "red")]) "red" <> ".")

    , "linebreak" =:
      "first\nsecond" =?>
      para ("first" <> linebreak <> "second")

    , "link" =:
      "[Example|https://example.org]" =?>
      para (link "https://example.org" "" "Example")

    , "image" =:
      "!https://example.com/image.jpg!" =?>
      para (image "https://example.com/image.jpg" "" mempty)

    , "thumbnail image" =:
      "!image.jpg|thumbnail!" =?>
      para (imageWith ("", ["thumbnail"], []) "image.jpg" "" mempty)

    , "image with attributes" =:
      "!image.gif|align=right, vspace=4, title=Hello!" =?>
      let attr = ("", [], [("align", "right"), ("vspace", "4")])
      in para $ imageWith attr "image.gif" "Hello" mempty

    , "inserted text" =:
      "+the new version+" =?>
      para (spanWith ("", ["underline"], []) "the new version")

    , "HTML entity" =:
      "me &amp; you" =?> para "me & you"

    , "non-strikeout dashes" =:
      "20.09-15 2-678" =?>
      para "20.09-15 2-678"
    ]
  ]
