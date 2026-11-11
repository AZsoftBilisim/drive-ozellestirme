#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	InternationalReportingServer.OnComposeResult(DataCompositionSchema, SettingsComposer, ResultDocument, DetailsData, StandardProcessing);
	
	TotalArea = ResultDocument.FindText(NStr("vi = 'Phát sinh Nợ';
											|ru = 'Дебетовый оборот';
											|en = 'Debit turnover'; fa = 'گردش بدهکار';
											|it = 'Fatturato a debito';
											|pl = 'Obrót debetowy';
											|tr = 'Borç cirosu'"));
	Area = ResultDocument.FindText(NStr("vi = 'Tiền tệ báo cáo';
										|ru = 'Валюта отчета';
										|en = 'Report currency'; fa = 'ارز گزارش';
										|it = 'Valuta del report';
										|pl = 'Waluta raportu';
										|tr = 'Rapor para birimi'"));
	If Area <> Undefined And TotalArea <> Undefined Then
		For ColumnNumber = Area.Left + 1 To TotalArea.Left - 1 Do
			Column = "C"+String(ColumnNumber);
			AreaName = "R"+String(Area.Top)+Column+":R"+String(ResultDocument.FixedTop)+Column;
			CorAccountHeader = ResultDocument.Area(AreaName);
			CorAccountHeader.Merge();
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
