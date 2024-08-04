
# Pt

Process Template (POSIX)

Pt sources a file (for loading environment variables), applies variable substitution to a command and any files it finds in the arguments, and finally runs the command.

Important! Pt only subsitutes environment variables using the `${}` syntax. For example, `${SOME_VAR}` will be substituted, but `$ANOTHER_VAR` will not be substituted!

## Getting Started

Simply run the `install.sh` script:

```
curl -o- https://raw.githubusercontent.com/mkpsp/pt/main/install.sh | bash
```

Or, copy `src/pt` to a /bin directory and make it executable. The file is POSIX compatible and should work as long as you have the required dependent commands.

## Usage

```
pt ENVIRONMENT_FILE COMMAND_WITH_ARGS...
```

## Configuration

The following environment variables can be set to change the behavior of `pt`:

```
PT_DEFAULT_ENV        set to the path of a file to source before the env_file is sourced. defaults to 'default.env'
PT_FUNCTIONS_ENV      set to the path of a file to source after the env_file is sourced. default to 'functions.env'
PT_AUTO_APPROVE       if set to 'yes', the prompt will not be displayed and the command will automatically be run
PT_PRINT_K8S_CLUSTER  if set to 'yes', print the current kubernetes cluster in the INFO section
PT_SUB_MODE           if set to 'yes', pt will only template process files and echo the results
```

## Example

Take the following example:

```
# commands to run:

export CD_ENV_PATH="production.env"

pt $CD_ENV_PATH helm upgrade cluster-autoscaler autoscaler/cluster-autoscaler \
  --install --namespace kube-system --values \${CLOUD_PROVIDER}/values.yml

PT_SUB_MODE='yes' pt staging.env values.yml.tmpl > values.yml
```

```
# contents of production.env

export CLOUD_PROVIDER="aws"
```

### Sourced Files

`pt` will source the following files in this order:

- `default.env` (if exists, can be changed by setting `PT_DEFAULT_ENV`)
- the file passed as the first argument to pt
- `functions.env` (if exists, can be changed by setting `PT_FUNCTIONS_ENV`)

The reasoning behind this is that you may want a set of default environment variables to be applied which should be set in `defaults.env`. 

Then you'll have the variables in the file you specify sourced (in this case the value of `${CD_ENV_PATH}` which is `production.env`) and this will overwrite any defaults. 

Finally, `functions.env` can define any shell functions you want to run to generate more variables that can be used. For example, you can use a function to convert a comma-separated list into the correct format you need for your files.

### Base64 Variables

Then, the command will create base64 versions of all your environment variables in your shell, including any that were sourced in the previous step. For example, if the variable `SOME_VAR` exists, the command will create `SOME_VAR_BASE64` which will be available for substitution in your template file.

### Substitute Variables In Command

The command will then substitute any environment variables it finds in the arguments. In this case, it will substitute anything it finds in:

```
$CD_ENV_PATH helm upgrade cluster-autoscaler autoscaler/cluster-autoscaler --install --namespace kube-system --values \${CLOUD_PROVIDER}/values.yml
```

The shell will substitute `$CD_ENV_PATH`, but `pt` will substitute `\${CLOUD_PROVIDER}`. The dollar sign is escaped to prevent the shell from substituting the variable. This allows you to define `CLOUD_PROVIDER` in your environment file to be used in making substitutions in your command. This makes your command completely reusable across environments with all of the environment specific information being stored in the environment file.

### Determine Template File And Create A Temporary Copy

`pt` will attempt to automatically find all files for templating. It does this by traversing your command's arguments and testing if any are files. In this example, `\${CLOUD_PROVIDER}/values.yml` will be processed.

The original files are now copied to a hidden dot file. For example, `values.yml` will be stored in `.values.yml` while `values.yml` will now be used to store the final post-substitution file.

### Apply Environment Substitution

`pt` will now substitute any environment variables into the template files that use the `${}` variable pattern. For example, `${SOME_VAR}` will be substituted, but `$ANOTHER_VAR` will not be substituted!

### Print The Result

The final post-substitution files will now be printed so that you can validate the result. 

If the command is a `helm` command or a `kubectl apply`, it will run and print a diff.

You can press enter to continue or `^C` to abort.

### Run The Command

Now the command you specified will be run, in this case:

```
helm upgrade cluster-autoscaler autoscaler/cluster-autoscaler \
  --install --namespace kube-system --values aws/values.yml
```

### Clean Up

Finally, after your command has run (or if you aborted), the original files will be restored to their original location.

## License

[Apache License 2.0](https://github.com/mkpsp/pt/blob/main/LICENSE)

---

Copyright 2024 Mkpsp LLC
