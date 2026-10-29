function age-edit --description 'Edit an age file using the default editor'
    cat $argv[1] \
        | age --decrypt -i $AGE_EDIT_ID \
        | vipe \
        | age --armor --encrypt -r $(age-keygen -y $AGE_EDIT_ID) \
        | sponge $argv[1]
end
