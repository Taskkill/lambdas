module Simply.Evaluator where

import Data.Set (Set)
import qualified Data.Set as Set

import Simply.AST (Expression(..))


normalize :: Expression -> Expression
normalize tree =
  if not (normalForm tree) then
    normalize (normalStep tree)
  else
    tree

normalForm :: Expression -> Bool
normalForm tree =
  case tree of
    Abstraction _ _ body -> normalForm body
    Application (Abstraction _ _ _) _ -> False
    Application left right -> normalForm left && normalForm right
    _ -> True
    -- Variable _ -> True
    -- Natural _ -> True
    -- Boolean _ -> True
    -- Macro _ -> True
    -- Operator _ -> True

normalStep :: Expression -> Expression
normalStep tree =
  case tree of
    Abstraction arg t body -> Abstraction arg t (normalStep body)
    Application (Abstraction arg _ body) right -> beta arg right (alpha arg (free right) body)
    Application left right ->
      if normalForm left then
        Application left (normalStep right)
      else Application (normalStep left) right
    _ -> tree

free :: Expression -> Set String
free = free2 Set.empty Set.empty

free2 :: Set String -> Set String -> Expression -> Set String
free2 bound freeVars tree =
  case tree of
    Variable name ->
      if Set.member name bound then
        freeVars
      else
        Set.insert name freeVars
    Abstraction arg _ body -> free2 (Set.insert arg bound) freeVars body
    Application left right ->
      let
        leftFree = free2 bound freeVars left
        rightFree = free2 bound freeVars right
      in
      Set.union leftFree rightFree
    _ -> freeVars -- Number, Boolean, Macro

alpha :: String -> Set String -> Expression -> Expression
alpha arg freeArg tree =
  let
    alphaCurr = alpha arg freeArg
  in
  case tree of
    Abstraction argument t body ->
      if argument == arg then -- shadowing
        tree
      else if Set.member arg (free body) && Set.member argument freeArg then
      -- free original Argument in Body && current Argument in conflict with free Vars from Right Value
        let
          newName = "_" ++ argument ++ "_"
          replacement = Variable ("_" ++ argument ++ "_")
        in
        Abstraction newName t (alphaCurr (beta argument replacement body))
      else tree
    Application left right -> Application (alphaCurr left) (alphaCurr right)
    _ -> tree

beta :: String -> Expression -> Expression -> Expression
beta arg value target =
  let
    betaCurr = beta arg value
  in
  case target of
    Variable name ->
      if arg == name then
        value
      else
        target
    Abstraction argName t body ->
      if arg == argName then
        target
      else
        Abstraction argName t (betaCurr body)
    Application left right -> Application (betaCurr left) (betaCurr right)
    _ -> target
    -- Natural n -> Natural n
    -- Macro t -> Macro t
    -- Boolean b -> Boolean b
    -- Operator op -> Operator op