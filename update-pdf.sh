#!/bin/bash

# Script לעדכון ה-PDF באתר
# בטוח - בודק שהכל עבד לפני commit

set -e  # עצור אם יש שגיאה

# צבעים להודעות
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔄 מתחיל עדכון PDF לאתר...${NC}"

# בדוק שאנחנו בתיקייה הנכונה
if [ ! -f "main.tex" ]; then
    echo -e "${RED}❌ שגיאה: לא נמצא main.tex. ודאי שאתה בתיקיית הפרויקט.${NC}"
    exit 1
fi

# בדוק ש-xelatex קיים
if ! command -v xelatex &> /dev/null; then
    echo -e "${RED}❌ שגיאה: xelatex לא נמצא. התקן LaTeX.${NC}"
    exit 1
fi

# קמפל את ה-PDF
echo -e "${YELLOW}📝 מקמפל main.tex...${NC}"
xelatex -interaction=nonstopmode main.tex > /dev/null 2>&1

# בדוק שה-PDF נוצר בהצלחה
if [ ! -f "main.pdf" ]; then
    echo -e "${RED}❌ שגיאה: הקומפילציה נכשלה - main.pdf לא נוצר.${NC}"
    exit 1
fi

# בדוק שה-PDF לא ריק
PDF_SIZE=$(stat -f%z main.pdf 2>/dev/null || stat -c%s main.pdf 2>/dev/null)
if [ "$PDF_SIZE" -lt 1000 ]; then
    echo -e "${RED}❌ שגיאה: ה-PDF שנוצר קטן מדי (כנראה ריק).${NC}"
    exit 1
fi

echo -e "${GREEN}✅ הקומפילציה הצליחה!${NC}"

# בדוק שתיקיית docs/assets קיימת
if [ ! -d "docs/assets" ]; then
    echo -e "${RED}❌ שגיאה: תיקיית docs/assets לא קיימת.${NC}"
    exit 1
fi

# שמור גיבוי של ה-PDF הישן (רק למקרה)
if [ -f "docs/assets/statistics_summary.pdf" ]; then
    cp docs/assets/statistics_summary.pdf docs/assets/statistics_summary.pdf.backup
    echo -e "${YELLOW}💾 שמרתי גיבוי של ה-PDF הישן${NC}"
fi

# העתק את ה-PDF החדש
echo -e "${YELLOW}📋 מעתיק PDF לאתר...${NC}"
cp main.pdf docs/assets/statistics_summary.pdf

# בדוק שההעתקה הצליחה
if [ ! -f "docs/assets/statistics_summary.pdf" ]; then
    echo -e "${RED}❌ שגיאה: ההעתקה נכשלה.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ה-PDF עודכן בהצלחה!${NC}"

# עדכן אוטומטית ב-git
echo -e "${YELLOW}📤 מעדכן git...${NC}"

# בדוק שיש שינויים
if git diff --quiet docs/assets/statistics_summary.pdf; then
    echo -e "${YELLOW}⚠️  אין שינויים ב-PDF - מדלג על commit${NC}"
else
    git add docs/assets/statistics_summary.pdf
    git commit -m "Update site PDF from main.tex"
    
    # בדוק אם יש שגיאות ב-git
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}🚀 דוחף ל-GitHub...${NC}"
        git push
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ הכל הצליח! ה-PDF יעודכן באתר תוך דקה-שתיים.${NC}"
        else
            echo -e "${RED}❌ שגיאה ב-push. בדוק את החיבור ל-GitHub.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ שגיאה ב-commit.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✨ סיימתי!${NC}"
