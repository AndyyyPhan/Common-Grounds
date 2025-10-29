{
  "env": {
    "node": true
  },
  "extends": [
    "eslint:recommended",
    "@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "project": "tsconfig.json",
    "sourceType": "module"
  },
  "plugins": [
    "@typescript-eslint"
  ],
  "rules": {
    "@typescript-eslint/ban-types": [
      "error",
      {
        "types": {
          "Function": false
        },
        "extendDefaults": true
      }
    ],
    "import/no-unresolved": 0,
    "indent": [
      "off"
    ]
  }
}
