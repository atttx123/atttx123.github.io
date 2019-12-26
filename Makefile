.PHONY: list

list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

clean:
	rm -rf public/ resources/

space := " "
today = $$(date +%Y-%m-%d)

new-post:
	@read -p "Enter Name: " name; \
	hugo new content/en/posts/$(today)-$${name// /-}.md; \
	hugo new content/zh/posts/$(today)-$${name// /-}.md

list-content:
	find "content" -name "*.md"

list-draft:
	find "content" -name "*.md" -exec grep --color -l "draft: true" {} +

list-finalize:
	find "content" -name "*.md" -exec grep --color -l "draft: false" {} +
