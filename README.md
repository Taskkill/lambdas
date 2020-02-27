# λ evaluator

## Currently working on implementations of Untyped, Simply Typed, and System F (λ, λ->, λ2)

### To test yourself:

```
$ stack build
```

#### Untyped
```
$ stack run untyped
```

#### Simply Typed
```
$ stack run simply
```

#### System F
```
$ stack run systemF
```

### Controls:
- write `λ` as `\`
- write `Λ` as `/`
- use numbers such as `23`
- Simple Types: `Nat` and `Bool`
- System F Types: `Nat` and `Bool`
- write System F type arguments as `[Nat]`
- you can omit redundant parentheses both in expressions and in type annotations

### Commands:
- `:step` for the next step of the evaluation
- `:type` for type annotation of the current expression
- `:isnormal` for checking if the expression is in the normal form
- `:applyto` for adding an argument to the current expression
- `:normalize` for the evaluation until the normal form is reached
- `:new` for inputting different expression
- `:bye` for exiting the program

#### Examples:

```
[enter λ expression]
:$ a b c (d e f g) h i
```

```
[enter λ-> expression]
:$ (\ a : Bool -> Bool -> Bool . (\ b : Bool -> Bool . (\ c : Bool . a (b c) c)))
[(Bool -> Bool -> Bool) -> (Bool -> Bool) -> Bool -> Bool] :: $ (λ a : Bool -> Bool -> Bool . (λ b : Bool -> Bool . (λ c : Bool . a (b c) c)))
```

```
[enter λ-> expression]
:$ (\ a : Bool -> Nat . (\ b : Bool . a b)) (\ e : Bool . 23) T
[Nat] :: $ (λ a : Bool -> Nat . (λ b : Bool . a b)) (λ e : Bool . 23) T
[command]:$ :normalize
[Nat] :: $ 23
```

```
[enter λ2 expression]
:$ (\ a : forall A . A -> A -> A . a) (/ B . (\t : B . (\f : B . t)))
:$ (λ a : (forall A . A -> A -> A) . a) (Λ B . (λ t : B . (λ f : B . t)))
[command or expression]:$ :type
[(forall A . A -> A -> A)]
:$ (λ a : (forall A . A -> A -> A) . a) (Λ B . (λ t : B . (λ f : B . t)))
```
More coming (hopefully) soon.