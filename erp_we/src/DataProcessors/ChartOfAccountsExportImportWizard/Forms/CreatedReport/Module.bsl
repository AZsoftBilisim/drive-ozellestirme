
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("SpreadsheetDocument", SpreadsheetDocument);
	Parameters.Property("ThisIsUpdateReport", ThisIsUpdateReport);
	
	If ThisIsUpdateReport Then
		
		Title = NStr("vi = 'Báo cáo về các phần từ được cập nhật';
					|ru = 'Отчет об обновленных элементах';
					|en = 'Updated items report'; fa = 'Updated items report';
					|it = 'Report su elementi aggiornati';
					|pl = 'Raport o zaktualizowanych elementach';
					|tr = 'Güncellenen öğeler hakkında rapor'");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SpreadsheetDocumentDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	
	StandardProcessing = False;
	If ValueIsFilled(Details) Then 
		ShowValue(,Details);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveTable(Command)
	
	If ThisIsUpdateReport Then
		
		TitleOfFileSelectionDialog = NStr("vi = 'Hãy chỉ ra tên tệp để lưu bảng các phần tử được cập nhật';
											|ru = 'Укажите имя файла для сохранения таблицы обновленных элементов';
											|en = 'To save the updated items table, specify the file name'; fa = 'To save the updated items table, specify the file name';
											|it = 'Specificare il nome del file per salvare la tabella di elementi aggiornati';
											|pl = 'Podaj nazwę pliku do zapisywania tabeli zaktualizowanych elementów';
											|tr = 'Güncellenmiş öğeler tablosunu kaydetmek için bir dosya adı belirtin'");
		FullFileName = NStr("vi = 'Bảng các phần tử được cập nhật';
							|ru = 'Таблица обновленных элементов';
							|en = 'Updated items table'; fa = 'Updated items table';
							|it = 'Tabella di elementi aggiornati';
							|pl = 'Tabele zaktualizowanych elementów';
							|tr = 'Güncellenmiş öğelerin tablosu'");
		
	Else
		
		TitleOfFileSelectionDialog = NStr("vi = 'Hãy chỉ ra tên tệp để lưu bảng các phần tử được tạo';
											|ru = 'Укажите имя файла для сохранения таблицы созданных элементов';
											|en = 'To save the created items table, specify the file name'; fa = 'To save the created items table, specify the file name';
											|it = 'Specificare il nome del file per salvare la tabella di elementi creati';
											|pl = 'Podaj nazwę pliku do zapisywania tabeli utworzonych elementów';
											|tr = 'Oluşturulmuş öğeler tablosunu kaydetmek için bir dosya adı belirtin'");
		FullFileName = NStr("vi = 'Bảng các phần tử đã tạo';
							|ru = 'Таблица созданных элементов';
							|en = 'Created items table'; fa = 'Created items table';
							|it = 'Tabella di elementi creati';
							|pl = 'Tabela utworzonych elementów';
							|tr = 'Oluşturulmuş öğeler tablosu'");
		
	EndIf;
	
	Notification = New CallbackDescription("AfterFileChoiceForSaving", ThisObject);
	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.Filter = NStr("vi = 'Sổ Excel 97 (*.xls)|*.xls|Sổ Excel 2007 (*.xlsx)|*.xlsx|Bảng điện tử OpenDocument (*.ods)|*.ods|Văn bản dạng bảng (*.mxl)|*.mxl';
							|ru = 'Книга Excel 97 (*.xls)|*.xls|Книга Excel 2007 (*.xlsx)|*.xlsx|Электронная таблица OpenDocument (*.ods)|*.ods|Табличный документ (*.mxl)|*.mxl';
							|en = 'Microsoft Excel 97 (*.xls)|*.xls|Microsoft Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Spreadsheet document (*.mxl)|*.mxl'; fa = 'Microsoft Excel 97 (*.xls)|*.xls|Microsoft Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Spreadsheet document (*.mxl)|*.mxl';
							|it = 'Libro Excel 97 (*.xls)|*.xls|Libro Excel 2007 (*.xlsx)|*.xlsx|Tabella Elettronica OpenDocument (*.ods)|*.ods|Documento tabulare (*.mxl)|*.mxl';
							|pl = 'Arkusz Excel 97 (*.xls)|*.xls|Arkusz Excel 2007 (*.xlsx)|*.xlsx|Tabela elektroniczna OpenDocument (*.ods)|*.ods|Dokument tabelaryczny (*.mxl)|*.mxl';
							|tr = 'Excel 97 kitabı (*.xls)|*.xls| Excel 2007 kitabı (*.xlsx)|*.xlsx|Elektronik tablo OpenDocument (*.ods)|*.ods|E-tablo belgesi (*.mxl)|*.mxl'");
	FileDialog.Title = TitleOfFileSelectionDialog;
	FileDialog.DefaultExt = "xls";
	FileDialog.Multiselect = False;
	FileDialog.FullFileName = FullFileName;
	FileDialog.FilterIndex = 0;
	FileSystemClient.ShowSelectionDialog(Notification, FileDialog);
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterFileChoiceForSaving(Result, AdditionalParameters) Export
	
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