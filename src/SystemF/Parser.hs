module SystemF.Parser where

import Text.ParserCombinators.ReadP

import qualified SystemF.AST as AST
import qualified SystemF.Types as Type
import SystemF.Tokens
import SystemF.Lexer

-- Type := Var
--       | (Type -> Type)
--       | Type -> Type [-> Type]
--       | (Type -> Type [-> Type])
-- TODO: need to expand

tVar :: ReadP Type.Type
tVar = do
  space <- skipSpaces
  p <- typeVar
  case p of TypeVar t -> return $ Type.Parameter t

tNat :: ReadP Type.Type
tNat = do
  space <- skipSpaces
  string "Nat"
  return Type.Nat

tBool :: ReadP Type.Type
tBool = do
  space <- skipSpaces
  string "Bool"
  return Type.Boolean

leftPart :: ReadP Type.Type
leftPart = do
  left <- choice [tVar, tNat, tBool, wrapTArr]
  space <- skipSpaces
  arrow <- arr
  return $ left

tArr :: ReadP Type.Type
tArr = do
  tps <- many1 $ choice [leftPart, tVar, tNat, tBool, wrapTArr] -- ...leftPart : one of the others : []
  return $ foldr (\tx ta -> Type.Arr tx ta) (last tps) (init tps)

wrapTArr :: ReadP Type.Type
wrapTArr = do
  s <- skipSpaces
  l <- leftParen
  arr <- tArr
  s <- skipSpaces
  r <- rightParen
  return arr

typeAnnotation :: ReadP Type.Type
typeAnnotation =
  choice [tVar, tNat, tBool, wrapTArr, tArr]
  

-- EXP := VAR
--      | EXP EXP
--      | (λ VAR . EXP)
--      | NUMBER
--      | MACRO
--      | (EXP)
-- TODO: need to expand

typeParameter :: ReadP Type.Type
typeParameter = do
  space <- skipSpaces
  l <- leftBracket
  space <- skipSpaces
  t <- typeAnnotation
  space <- skipSpaces
  r <- rightBracket
  return t

variable :: ReadP AST.Expression
variable = do
  space <- skipSpaces
  id <- var
  case id of Identifier name -> return $ AST.Variable name

natural' :: ReadP AST.Expression
natural' = do
  space <- skipSpaces
  num <- natural
  case num of Natural int -> return $ AST.Natural int

macro' :: ReadP AST.Expression
macro' = do
  space <- skipSpaces
  m <- macro
  case m of Macro str -> return $ AST.Macro str

operator' :: ReadP AST.Expression
operator' = do
  space <- skipSpaces
  op <- operator
  case op of Operator str -> return $ AST.Operator str

-- application :: ReadP AST.Expression
-- application = do
--   left <- choice [wrapped, variable, operator', macro', natural', abstraction, typeAbstraction]
--   ids <- many1 $ choice [wrapped, variable, operator', macro', natural', abstraction, typeAbstraction]
--   return $ foldl (\exp id -> AST.Application exp id) left ids

-- typeApplication :: ReadP AST.Expression
-- typeApplication = do
--   left <- choice [wrapped, variable, operator', macro', natural', abstraction, typeAbstraction]
--   params <- many1 $ typeParameter
--   return $ foldl (\exp par -> AST.TypeApplication exp par) left params


data Argument
  = Ex AST.Expression
  | Tp Type.Type

wrap :: ReadP AST.Expression -> ReadP Argument
wrap reader = do
  ex <- reader
  return $ Ex ex

wrap' :: ReadP Type.Type -> ReadP Argument
wrap' reader = do
  tp <- reader
  return $ Tp tp

makeApp :: AST.Expression -> Argument -> AST.Expression
makeApp left (Ex ex) = AST.Application left ex
makeApp left (Tp tp) = AST.TypeApplication left tp

combinedApplication :: ReadP AST.Expression
combinedApplication = do
  left <- choice [wrapped, variable, operator', macro', natural', abstraction, typeAbstraction]
  args <- many1 $ choice [wrap $ choice [wrapped, variable, operator', macro', natural', abstraction, typeAbstraction], wrap' typeParameter]
  return $ foldl makeApp left args

abstraction :: ReadP AST.Expression
abstraction = do
  space <- skipSpaces
  l <- leftParen
  space <- skipSpaces
  lam <- fnLambda
  space <- skipSpaces
  arg <- var
  space <- skipSpaces
  dd <- colon
  space <- skipSpaces
  type' <- typeAnnotation
  space <- skipSpaces
  d <- dot
  space <- skipSpaces
  exp <- expression
  space <- skipSpaces
  r <- rightParen
  case arg of Identifier name -> return $ AST.Abstraction name type' exp

typeAbstraction :: ReadP AST.Expression
typeAbstraction = do
  space <- skipSpaces
  l <- leftParen
  space <- skipSpaces
  lam <- tpLambda
  space <- skipSpaces
  param <- typeVar
  space <- skipSpaces
  d <- dot
  space <- skipSpaces
  exp <- expression
  space <- skipSpaces
  r <- rightParen
  case param of TypeVar p -> return $ AST.TypeAbstraction p exp

wrapped :: ReadP AST.Expression
wrapped = do
  space <- skipSpaces
  l <- leftParen
  space <- skipSpaces
  exp <- expression
  space <- skipSpaces
  r <- rightParen
  space <- skipSpaces
  return exp

-- default: (Λ A . (λ a : A -> A . (λ b : A . a b))) [Nat] (λ a : Nat -> Nat . a) 23 OK
-- TODO: take care of exprs: (λ a : Nat -> Boolean, b : Boolean -> Char, c : Nat . b (a c))
expression :: ReadP AST.Expression
expression =  
  choice [variable, natural', macro', operator', combinedApplication, abstraction, typeAbstraction, wrapped]