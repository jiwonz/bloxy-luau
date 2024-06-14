export type Command<T> = {
	name: string,
	description: string,
	run: (T) -> (),
	args: (parser: any) -> ()
}

return nil
