def 'is-installed' [ app: string ] {
  ((which $app | length) > 0)
}
