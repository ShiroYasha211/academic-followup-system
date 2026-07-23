<?php

namespace App\Services;

use PhpOffice\PhpSpreadsheet\Cell\DataType;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ClinicalEvaluationPortfolioExcelExporter
{
    public function download(array $portfolio): StreamedResponse
    {
        $spreadsheet = new Spreadsheet();
        $this->buildSummarySheet($spreadsheet, $portfolio);
        $this->buildAttemptsSheet($spreadsheet, $portfolio);
        $spreadsheet->setActiveSheetIndex(0);

        $student = $portfolio['student'];
        $filename = 'clinical_evaluations_'
            . ($student['student_number'] ?: $student['id'])
            . '_' . now()->format('Y-m-d') . '.xlsx';

        return response()->streamDownload(
            function () use ($spreadsheet) {
                (new Xlsx($spreadsheet))->save('php://output');
                $spreadsheet->disconnectWorksheets();
            },
            $filename,
            ['Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
        );
    }

    protected function buildSummarySheet(Spreadsheet $spreadsheet, array $portfolio): void
    {
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('الملخص');
        $sheet->setRightToLeft(true);
        $student = $portfolio['student'];
        $summary = $portfolio['summary'];

        $sheet->mergeCells('A1:G1');
        $sheet->setCellValue('A1', 'كشف التقييمات السريرية التراكمي');
        $sheet->fromArray([
            ['الطالب', $student['name'], 'الرقم الجامعي', $student['student_number'], 'التخصص', $student['major']['name'] ?? '-', 'المستوى'],
            ['', '', '', '', '', '', $student['level']['name'] ?? '-'],
        ], null, 'A3');

        $sheet->fromArray([
            ['إجمالي المحاولات', 'القوائم المختلفة', 'الدكاترة', 'المتوسط', 'أعلى نتيجة', 'نسبة النجاح', 'إجمالي الوقت'],
            [
                $summary['attempts_count'],
                $summary['checklists_count'],
                $summary['doctors_count'],
                $summary['average_percentage'] . '%',
                $summary['highest_percentage'] . '%',
                $summary['pass_rate'] . '%',
                $summary['formatted_total_time'],
            ],
        ], null, 'A6');

        $sheet->fromArray([[
            'قائمة OSCE',
            'نوع المهارة',
            'عدد المحاولات',
            'الدكاترة',
            'المتوسط',
            'أعلى نتيجة',
            'آخر تقييم',
        ]], null, 'A10');

        $row = 11;
        foreach ($portfolio['checklists'] as $checklist) {
            $sheet->fromArray([[
                $checklist['title'],
                $checklist['skill_label'],
                $checklist['attempts_count'],
                collect($checklist['doctors'])->pluck('name')->implode('، '),
                $checklist['average_percentage'] . '%',
                $checklist['highest_percentage'] . '%',
                $this->formatDate($checklist['last_evaluation_at']),
            ]], null, "A{$row}");
            $row++;
        }

        $this->styleSheet($sheet, 'A3:G' . max(10, $row - 1));
        $this->styleTitle($sheet, 'A1:G1');
        $this->styleHeader($sheet, 'A6:G6');
        $this->styleHeader($sheet, 'A10:G10');
        $sheet->freezePane('A11');
        $this->setWidths($sheet, [24, 20, 16, 28, 14, 14, 19]);
    }

    protected function buildAttemptsSheet(Spreadsheet $spreadsheet, array $portfolio): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle('المحاولات');
        $sheet->setRightToLeft(true);
        $sheet->fromArray([[
            '#',
            'قائمة OSCE',
            'نوع المهارة',
            'الدكتور',
            'نظام الجسم',
            'الحالة السريرية',
            'الدرجة',
            'النسبة',
            'التقدير',
            'الوقت',
            'التاريخ',
            'ملاحظات الدكتور',
        ]], null, 'A1');

        $row = 2;
        foreach ($portfolio['attempts'] as $index => $attempt) {
            $sheet->fromArray([[
                $index + 1,
                $attempt['checklist']['title'] ?? '-',
                $attempt['checklist']['skill_label'] ?? '-',
                $attempt['doctor']['name'] ?? '-',
                $attempt['body_system']['name'] ?? '-',
                $attempt['clinical_case']['name'] ?? '-',
                $attempt['total_score'] . ' / ' . $attempt['max_score'],
                $attempt['percentage'] . '%',
                $attempt['grade_label'],
                $attempt['formatted_time'],
                $attempt['display_date'],
                $attempt['doctor_feedback'] ?: '-',
            ]], null, "A{$row}");
            $sheet->setCellValueExplicit("A{$row}", (string) ($index + 1), DataType::TYPE_NUMERIC);
            $row++;
        }

        $this->styleSheet($sheet, 'A1:L' . max(1, $row - 1));
        $this->styleHeader($sheet, 'A1:L1');
        $sheet->freezePane('A2');
        $sheet->setAutoFilter('A1:L' . max(1, $row - 1));
        $this->setWidths($sheet, [7, 26, 18, 22, 18, 24, 14, 12, 14, 12, 20, 38]);
    }

    protected function styleTitle($sheet, string $range): void
    {
        $sheet->getStyle($range)->applyFromArray([
            'font' => ['bold' => true, 'size' => 16, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '183B56']],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
                'vertical' => Alignment::VERTICAL_CENTER,
            ],
        ]);
        $sheet->getRowDimension(1)->setRowHeight(30);
    }

    protected function styleHeader($sheet, string $range): void
    {
        $sheet->getStyle($range)->applyFromArray([
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '2563A8']],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
                'vertical' => Alignment::VERTICAL_CENTER,
            ],
        ]);
    }

    protected function styleSheet($sheet, string $range): void
    {
        $sheet->getStyle($range)->applyFromArray([
            'font' => ['name' => 'Arial', 'size' => 10],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_RIGHT,
                'vertical' => Alignment::VERTICAL_CENTER,
                'wrapText' => true,
            ],
            'borders' => [
                'allBorders' => [
                    'borderStyle' => Border::BORDER_THIN,
                    'color' => ['rgb' => 'DCE4EC'],
                ],
            ],
        ]);
    }

    protected function setWidths($sheet, array $widths): void
    {
        foreach ($widths as $index => $width) {
            $column = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($index + 1);
            $sheet->getColumnDimension($column)->setWidth($width);
        }
    }

    protected function formatDate(?string $value): string
    {
        return $value ? date('Y-m-d H:i', strtotime($value)) : '-';
    }
}
