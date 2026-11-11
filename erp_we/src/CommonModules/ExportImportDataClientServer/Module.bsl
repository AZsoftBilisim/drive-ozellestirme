////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// the name of the data upload file.
// 
// Returns: 
//  String - the name of the data upload file.
Function NameOfDataUploadFile() Export

	Return "data_dump.zip"

EndFunction

Function LongTermOperationHint() Export
	Return NStr("vi = 'Thao tác có thể mất nhiều thời gian. Vui lòng đợi...';
				|ru = 'Операция может занять длительное время. Пожалуйста, подождите...';
				|en = 'The operation might take a long time. Please wait...'; fa = 'The operation might take a long time. Please wait...';
				|it = 'Операция может занять длительное время. Пожалуйста, подождите...';
				|pl = 'The operation might take a long time. Please wait...';
				|tr = 'İşlem uzun sürebilir. Lütfen bekleyin...'");
EndFunction

Function ExportImportDataAreaPreparationStateView(importDataArea) Export
	If importDataArea Then
		StatusPresentation = NStr("vi = 'Đang thực hiện chuẩn bị kết nhập dữ liệu.';
									|ru = 'Выполняется подготовка к загрузке данных.';
									|en = 'Preparing to import data.'; fa = 'Preparing to import data.';
									|it = 'Выполняется подготовка к загрузке данных.';
									|pl = 'Preparing to import data.';
									|tr = 'Veri içe aktarımına hazırlık yapılıyor.'");
	Else
		StatusPresentation = NStr("vi = 'Đang thực hiện chuẩn bị kết xuất dữ liệu.';
									|ru = 'Выполняется подготовка к выгрузке данных.';
									|en = 'Preparing to export data.'; fa = 'Preparing to export data.';
									|it = 'Выполняется подготовка к выгрузке данных.';
									|pl = 'Preparing to export data.';
									|tr = 'Veri dışa aktarımına hazırlık yapılıyor.'");
	EndIf;
	Return StatusPresentation;
EndFunction

#EndRegion