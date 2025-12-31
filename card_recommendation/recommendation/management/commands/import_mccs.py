import csv
from django.core.management.base import BaseCommand
from recommendation.models import MerchantCategoryCode

class Command(BaseCommand):
    help = "Import MCC codes from a CSV file"

    def add_arguments(self, parser):
        parser.add_argument("csv_file", type=str, help="Path to the mcc_codes.csv file")

    def handle(self, *args, **kwargs):
        csv_file = kwargs["csv_file"]
        created_count = 0
        updated_count = 0

        with open(csv_file, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)

            for row in reader:
                code = row["mcc"].strip().zfill(4)  # pad e.g., 742 → 0742
                description = row.get("combined_description") or row.get("edited_description")
                if description:
                    description = description.strip()

                if not code or not description:
                    self.stdout.write(self.style.WARNING(f"⚠️ Skipped row with missing code or description: {row}"))
                    continue

                obj, created = MerchantCategoryCode.objects.update_or_create(
                    code=code,
                    defaults={"description": description}
                )
                if created:
                    created_count += 1
                else:
                    updated_count += 1

        self.stdout.write(self.style.SUCCESS(f"✅ Import complete: {created_count} created, {updated_count} updated."))