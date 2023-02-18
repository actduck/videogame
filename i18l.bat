echo Start process 1
call flutter pub global activate intl_utils
echo Start process 2
call flutter --no-color pub global run intl_utils:generate
