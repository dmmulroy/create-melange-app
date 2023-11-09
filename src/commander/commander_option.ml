type value = [ `bool of bool | `string of string | `strings of string array ]

type t = {
  flags : string;
  description : string;
  required : bool;
  optional : bool;
  variadic : bool;
  mandatory : bool;
  short : string option;
  long : string option;
  negate : bool;
  default_value : value option; [@mel.as "defaultValue"]
  default_value_description : string option; [@mel.as "defaultValueDescription"]
  preset_arg : value option; [@mel.as "presetArg"]
  env_var : string option; [@mel.as "envVar"]
  parse_arg : (value:string -> previous:value -> value) option;
      [@mel.as "parseArg"]
  hidden : bool;
  arg_choices : string array option; [@mel.as "argChoices"]
}

external commander_option : ?flags:string -> ?description:string -> unit -> t
  = "Option"
[@@mel.new] [@@mel.module "commander"]

(* onstructor(flags: string, description?: string);

   external program : ?name:string -> unit -> t = "Command"
   [@@mel.new] [@@mel.module "commander"]

        /**
         * Set the default value, and optionally supply the description to be displayed in the help.
         */
        default(value: unknown, description?: string): this;

        /**
         * Preset to use when option used without option-argument, especially optional but also boolean and negated.
         * The custom processing (parseArg) is called.
         *
         * @example
         * ```ts
         * new Option('--color').default('GREYSCALE').preset('RGB');
         * new Option('--donate [amount]').preset('20').argParser(parseFloat);
         * ```
         */
        preset(arg: unknown): this;

        /**
         * Add option name(s) that conflict with this option.
         * An error will be displayed if conflicting options are found during parsing.
         *
         * @example
         * ```ts
         * new Option('--rgb').conflicts('cmyk');
         * new Option('--js').conflicts(['ts', 'jsx']);
         * ```
         */
        conflicts(names: string | string[]): this;

        /**
         * Specify implied option values for when this option is set and the implied options are not.
         *
         * The custom processing (parseArg) is not called on the implied values.
         *
         * @example
         * program
         *   .addOption(new Option('--log', 'write logging information to file'))
         *   .addOption(new Option('--trace', 'log extra details').implies({ log: 'trace.txt' }));
         */
        implies(optionValues: OptionValues): this;

        /**
         * Set environment variable to check for option value.
         *
         * An environment variables is only used if when processed the current option value is
         * undefined, or the source of the current value is 'default' or 'config' or 'env'.
         */
        env(name: string): this;

        /**
         * Calculate the full description, including defaultValue etc.
         */
        fullDescription(): string;

        /**
         * Set the custom handler for processing CLI option arguments into option values.
         */
        argParser<T>(fn: (value: string, previous: T) => T): this;

        /**
         * Whether the option is mandatory and must have a value after parsing.
         */
        makeOptionMandatory(mandatory?: boolean): this;

        /**
         * Hide option in help.
         */
        hideHelp(hide?: boolean): this;

        /**
         * Only allow option value to be one of choices.
         */
        choices(values: readonly string[]): this;

        /**
         * Return option name.
         */
        name(): string;

        /**
         * Return option name, in a camelcase format that can be used
         * as a object attribute key.
         */
        attributeName(): string;

        /**
         * Return whether a boolean option.
         *
         * Options are one of boolean, negated, required argument, or optional argument.
         */
        isBoolean(): boolean;
      } *)
