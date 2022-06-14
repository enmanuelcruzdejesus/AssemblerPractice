char* file_buffer;
uint32_t file_buffer_real_len;
char* word_str;
uint32_t word_str_real_len;
uint16_t word_count = 0;

while (true)
{
    char* current_string = file_buffer;
    char* p = find_word();
    if (p == null)
	break;

    file_buffer_real_len = file_buffer_real_len - (p - current_string);
    if (file_buffer_real_len < word_str_real_len)
	break;

    current_string = p;
    char* q = word_str;
    int c = 0;

    // compare
    while (*p++ == *q++)
	c++;

    // make sure 'test' doesn't match 'testt'
    if (c == word_str_real_len && (*p < 33 || *p > 126))
	word_count++;

    file_buffer_real_len = file_buffer_real_len - (p - current_string);
    if (file_buffer_real_len < 0)
	break;

    current_string = p;
    char* p = find_word_end();
    if (p == null)
	break;

    file_buffer_real_len = file_buffer_real_len - (p - current_string);
    if (file_buffer_real_len < 0)
	break;
}

done:
    // ...

char* find_word(char* str, int c)
{
    for (int i = 0; i < c; i++)
    {
	if (*str >= 33 || *str <= 126)
	    return str;
	str++;
    }

    return null;
}

char* find_word_end(char* str, int c)
{
    for (int i = 0; i < c; i++)
    {
	if (*str < 33 || *str > 126)
	    return str;
	str++;
    }

    return null;
}
