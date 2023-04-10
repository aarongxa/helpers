#!/bin/bash
# Generate my weekly notes template in Markdown

# Get the current date in seconds since the Unix epoch
current_date=$(date +%s)

# Loop through the next 5 days
for i in $(seq 0 4); do
  # Calculate the date for the current iteration
  next_date=$(date -d "@$((current_date + (i * 86400)))" "+%B %d, %Y")

  # Print the markdown template for the current day
  echo "## Day $i: $next_date"
  echo ""
  echo "### Summary"
  echo ""
  echo "- A"
  echo "- B"
  echo "- C"
  echo ""
  echo "### Tasks"
  echo ""
  echo "- [ ]"
  echo "- [ ]"
  echo "- [ ]"
  echo ""
done

# Print the markdown template for the weekly summary
echo "## Weekly Summary"
echo ""
echo "### Achievements"
echo ""
echo "- A"
echo "- B"
echo "- C"
echo ""
echo "### Challenges"
echo ""
echo "- A"
echo "- B"
echo "- C"
echo ""
echo "### Goals for Next Week"
echo ""
echo "- [ ]"
echo "- [ ]"
echo "- [ ]"
echo ""

