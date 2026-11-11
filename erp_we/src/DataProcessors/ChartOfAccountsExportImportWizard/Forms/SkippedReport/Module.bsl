#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("SpreadsheetDocument", SpreadsheetDocument);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SpreadsheetDocumentDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	StandardProcessing = False;;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveTableOfMissed(Command)
	
	Notification = New CallbackDescription("AfterSelectingFileToSaveTableOfMissed", ThisObject);
	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.Filter = NStr("vi = 'Sổ Excel 97 (*.xls)|*.xls|Sổ Excel 2007 (*.xlsx)|*.xlsx|Bảng điện tử OpenDocument (*.ods)|*.ods|Văn bản dạng bảng (*.mxl)|*.mxl';
							|ru = 'Книга Excel 97 (*.xls)|*.xls|Книга Excel 2007 (*.xlsx)|*.xlsx|Электронная таблица OpenDocument (*.ods)|*.ods|Табличный документ (*.mxl)|*.mxl';
							|en = 'Microsoft Excel 97 (*.xls)|*.xls|Microsoft Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Spreadsheet document (*.mxl)|*.mxl'; fa = 'Microsoft Excel 97 (*.xls)|*.xls|Microsoft Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Spreadsheet document (*.mxl)|*.mxl';
							|it = 'Libro Excel 97 (*.xls)|*.xls|Libro Excel 2007 (*.xlsx)|*.xlsx|Tabella Elettronica OpenDocument (*.ods)|*.ods|Documento tabulare (*.mxl)|*.mxl';
							|pl = 'Arkusz Excel 97 (*.xls)|*.xls|Arkusz Excel 2007 (*.xlsx)|*.xlsx|Tabela elektroniczna OpenDocument (*.ods)|*.ods|Dokument tabelaryczny (*.mxl)|*.mxl';
							|tr = 'Excel 97 kitabı (*.xls)|*.xls| Excel 2007 kitabı (*.xlsx)|*.xlsx|Elektronik tablo OpenDocument (*.ods)|*.ods|E-tablo belgesi (*.mxl)|*.mxl'");
	FileDialog.Title = NStr("vi = 'Hãy chỉ ra tên tệp để lưu bảng các phần tử bị bỏ qua';
							|ru = 'Укажите имя файла для сохранения таблицы пропущенных элементов';
							|en = 'To save the skipped items table, specify the file name'; fa = 'To save the skipped items table, specify the file name';
							|it = 'Specificare il nome del file per salvare la tabella di elementi omessi';
							|pl = 'Podaj nazwę pliku do zapisywania tabeli pominiętych elementów';
							|tr = 'Eksik öğeler tablosunu kaydetmek için bir dosya adı belirtin'");
	FileDialog.DefaultExt = "xls";
	FileDialog.Multiselect = False;
	FileDialog.FullFileName = NStr("vi = 'Bảng các phần tử bị bỏ qua';
									|ru = 'Таблицы пропущенных элементов';
									|en = 'Skipped items tables'; fa = 'Skipped items tables';
									|it = 'Tabella di elementi omessi';
									|pl = 'Tabele pominiętych elementów';
									|tr = 'Eksik öğeler tabloları'");
	FileDialog.FilterIndex = 0;
	FileSystemClient.ShowSelectionDialog(Notification, FileDialog);
	
EndProcedure

&AtClient
Procedure UploadAgain(Command)
	
	Close(SpreadsheetDocument);
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterSelectingFileToSaveTableOfMissed(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		AddressInTempStorage = GenerateFileOnServer(SpreadsheetDocument, Result[0]);
		FileSystemClient.SaveFile(Undefined, AddressInTempStorage, Result[0]);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GenerateFileOnServer(SpreadsheetDocument, FullFileName)
	
	FileExtention = CommonClientServer.ExtensionWithoutPoint(CommonClientServer.GetFileNameExtension(FullFileName));;
	
	FileName = GetTempFileName(FileExtention);
	If FileExtention = "xlsx" Then
		
		SpreadsheetDocument.Write(FileName, SpreadsheetDocumentFileType.XLSX);
		
	ElsIf FileExtention = "xls" Then
		
		SpreadsheetDocument.Write(FileName, SpreadsheetDocumentFileType.XLS);
		
	ElsIf FileExtention = "ods" Then
		
		SpreadsheetDocument.Write(FileName, SpreadsheetDocumentFileType.ODS);
		
	Else 
		
		SpreadsheetDocument.Write(FileName, SpreadsheetDocumentFileType.MXL);
		
	EndIf;
	
	BinaryData = New BinaryData(FileName);
	
	AddressInTempStorage = PutToTempStorage(BinaryData, AddressInTempStorage);
	
	FileSystem.DeleteTempFile(FileName);
	
	Return AddressInTempStorage;
	
EndFunction

#EndRegion