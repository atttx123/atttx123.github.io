.PHONY: list

list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

clean:
	rm -rf public/ resources/

today = $$(date +%Y-%m-%d)

new-zh:
	@read -p "Enter Name: " name; \
	hugo new content/zh/posts/$(today)-$$name.md

new-en:
	@read -p "Enter Name: " name; \
	hugo new content/en/posts/$(today)-$$name.md

new-all:
	@read -p "Enter Name: " name; \
	hugo new content/zh/posts/$(today)-$$name.md
	hugo new content/en/posts/$(today)-$$name.md

list-content:
	find "content" -name "*.md"

list-draft:
	find "content" -name "*.md" -exec grep --color -l "draft: true" {} +
