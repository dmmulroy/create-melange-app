export const SOME: unique symbol = Symbol("SOME");
export const NONE: unique symbol = Symbol("NONE");

export type SomeValue<T> = T extends null | undefined | None ? never : T;
export type Option<T> = None | Some<T>;

type Some<A> = Readonly<{
  kind: typeof SOME;
  value: SomeValue<A>;
  return(value: SomeValue<A>): Some<A>;
  map<B>(fn: (value: SomeValue<A>) => SomeValue<B>): Some<B>;
  andThen<B>(fn: (value: SomeValue<A>) => Option<B>): Option<B>;
  unwrap(): A;
  match<B>(match: {
    some: (value: SomeValue<A>) => SomeValue<B>;
    none: (_: never) => B;
  }): SomeValue<B>;
}>;

type None = Readonly<{
  kind: typeof NONE;
  return(): None;
  map<B>(fn: (_: never) => B): None;
  andThen<B>(fn: (_: never) => Option<B>): None;
  unwrap(): never;
  match<B>(pattern: { some: (_: never) => B; none: (_: never) => B }): B;
}>;

const Some = {
  return<A>(value: SomeValue<A>): Some<A> {
    return {
      kind: SOME,
      value,
      return: Some.return,
      map(fn) {
        return Some.return(fn(value));
      },
      andThen(fn) {
        return fn(value);
      },
      unwrap() {
        return value;
      },
      match(match) {
        return match.some(value);
      },
    };
  },
};

const None = {
  return(): None {
    const self = {
      kind: NONE,
      return() {
        return self;
      },
      map() {
        return self;
      },
      andThen() {
        return self;
      },
      unwrap() {
        throw new Error("Cannot unwrap None");
      },
      match<B>(match: { some: (_: never) => B; none: () => B }) {
        return match.none();
      },
    } as const;

    return self;
  },
};

const Option = {
  some: Some.return,
  none: None.return,
  isSome<A>(option: Option<A>): option is Some<A> {
    return option.kind === SOME;
  },
  isNone<A>(option: Option<A>): option is None {
    return option.kind === NONE;
  },
  unwrap<A>(option: Option<A>): A {
    return option.unwrap();
  },
};

// Type of `someValue` is Option<number>
const someValue = Option.some(1)
  .map((value) => (Math.random() >= 0.5 ? value + 1 : value - 1))
  .andThen((value) => (value >= 1 ? Option.some(value) : Option.none()));

// Type of `matchedValue` is `string`
const matchedValue = someValue.match({
  some(value) {
    return `our value is: ${value}`;
  },
  none() {
    return "no value";
  },
});

// Be careful, this can throw an error!
// If `someValue` is our `Some` variant,
// the type of `unwrappedValue` will be `number`
const unwrappedValue = someValue.unwrap();

// Invalid option constructors that cause type errors
const invalidOption = Option.some(null);
const invalidOption = Option.some(undefined);
const invalidOption = Option.some(Option.none());
