module Clap

import "std/datatypes/str.rl";
import "std/utils.rl";

enum ArgTy {
    TwoHyph = 1 << Utils::iota(),
    OneHyph = 1 << Utils::iota(),
    Literal = 1 << Utils::iota(),
    Assign = 1 << Utils::iota(),
    Invalid = 1 << Utils::iota(),
}

### Class
#-- Name: Arg
#-- Parameter: lx: str
#-- Parameter: ty: int
#-- Parameter: eq: option<str>
#-- Description:
#--   A class that represents a CLI argument.
#--   Takes `lx` (literal), `ty` (type), and `eq` (rhs of assignment).
@pub @experimental
class Arg [lx: str, ty: int, eq: option] {
    @pub let lx = lx;
    @pub let ty = ty;
    @pub let eq = eq;

    @pub fn is_one_hyph() {
        return (this.ty `& ArgTy.OneHyph) != 0;
    }

    @pub fn is_two_hyph() {
        return (this.ty `& ArgTy.TwoHyph) != 0;
    }

    @pub fn is_literal() {
        return (this.ty `& ArgTy.Literal) != 0;
    }

    @pub fn is_assignment() {
        return (this.ty `& ArgTy.Assign) != 0;
    }

    @pub fn is_invalid() {
        return (this.ty `& ArgTy.Invalid) != 0;
    }

    @pub fn get_assignment() {
        if !this.is_assignment() {
            panic(__FILE__, ' ', __FUNC__, ": `", this.lx, "` is not an assignment flag");
        }
        assert(this.eq);
        return (this.lx, this.eq.unwrap());
    }

    @pub fn get_actual() {
        let s = this.lx;
        if this.is_assignment() {
            s += "=" + this.eq.unwrap();
        }
        return s;
    }
}
### End

fn determine_eq(@const @ref s) {
    let idx = Str::find(s, '=');
    if idx {
        let idxu = idx.unwrap();
        return some(
            (
                s.substr(0, idxu),
                s.substr(idxu+1, len(s)),
            )
        );
    }
    return none;
}

### Function
#-- Name: parse
#-- Param: args: list<str>
#-- Returns: list<Arg>
#-- Description:
#--   Takes command line arguments and creates a
#--   list of `Arg`s that classifies them.
@pub @experimental
fn parse(args: list): list {
    let res = [];

    foreach arg in args {
        if arg[0] != '-' {
            let eq = determine_eq(arg);
            if eq {
                let l, r = eq.unwrap();
                res.append(Arg(l, ArgTy.Literal `| ArgTy.Assign, some(r)));
            }
            else {
                res.append(Arg(arg, ArgTy.Literal, none));
            }
        }
        else if len(arg) > 2 && arg.substr(0, 2) == "--" {
            let lx = arg.substr(2, len(arg));
            let eq = determine_eq(lx);
            if eq {
                let l, r = eq.unwrap();
                res.append(Arg(l, ArgTy.TwoHyph `| ArgTy.Assign, some(r)));
            }
            else {
                res.append(Arg(lx, ArgTy.TwoHyph, none));
            }
        }
        else if len(arg) > 1 && arg[0] == '-' {
            foreach c in arg.substr(1, len(arg)) {
                res.append(Arg(str(c), ArgTy.OneHyph, none));
            }
        }
        else {
            res.append(Arg(arg, ArgTy.Invalid, none));
        }
    }

    return res;
}
### End
