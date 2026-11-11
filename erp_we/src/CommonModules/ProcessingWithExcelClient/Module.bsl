////////////////////////////////////////////////////////////////////////////////
// General procedures and functions for working with uploading and uploading from Excel
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Procedure-Upload to excel
//
// Parameters:
//  Form		 - ClientApplicationForm	 - the form of the document.
Procedure ExportToExcel(Form) Export 
	
	CallbackDescription = New CallbackDescription(
		"UploadToExcelExtensionEnabled",
		ThisObject,
		New Structure("Form", Form));
	
	CommonClient.CheckFileSystemExtensionAttached(CallbackDescription);
	
EndProcedure

// The procedure is to Choose the attached excel file
//
// Parameters:
//  Form - ClientApplicationForm - the form of the document:
//   * Object   - FormDataStructure - Data structure of the document form.
//   * Items - FormAllItems     - Document form elements.
//  NameOfSelectionElement - String - Name of the form element to return the selection notification to.
//
Procedure SelectAttachedExcelFile(Form, NameOfSelectionElement) Export 

	If Not ValueIsFilled(Form.Object.Ref) Then
		
		AdditionalParameters = New Structure("Form, NameOfSelectionElement", Form, NameOfSelectionElement);
		Notification = New CallbackDescription("SelectAttachedExcelFileResponseProcessing", ThisObject, AdditionalParameters);
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại và tiếp tục';
												|ru = 'Записать и продолжить';
												|en = 'Save and continue'; fa = 'Save and continue';
												|it = 'Registrare e continuare';
												|pl = 'Zapisz i kontynuuj';
												|tr = 'Kaydet ve devam et'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification, 
			NStr("vi = 'Trước khi kết nhập, cần ghi lại chứng từ. Điền bản ghi chứng từ và tiếp tục?';
				|ru = 'Перед загрузкой документ необходимо записать. Выполнить запись документа и продолжить?';
				|en = 'Save the document before importing. Do you want to save and continue?'; fa = 'Save the document before importing. Do you want to save and continue?';
				|it = 'Prima del caricamento è necessario registrare il documento. Effettuare la registrazione del documento e continuare?';
				|pl = 'Przed pobraniem dokument należy zapisać. Wykonać zapis dokumentu i kontynuować?';
				|tr = 'Belge yüklenmeden önce kaydedilmelidir. Belge kaydedilip devam edilsin mi?'"),
			Buttons);
		Return;
		
	EndIf; 
	
	CallbackDescription = New CallbackDescription(
		"SelectAttachedExcelFileExtensionConnected",
		ThisObject,
		New Structure("FilesOwner, FormItem", Form.Object.Ref, Form.Items[NameOfSelectionElement]));
	
	CommonClient.CheckFileSystemExtensionAttached(CallbackDescription);
	
EndProcedure

// Function-Load from excel
//
// Parameters:
//  Form					 - ClientApplicationForm - the form of the document.
//  AttachedFile		 - CatalogRef.PurchasePlanAttachedFiles - A link to the selected attached file.
//  						 - CatalogRef.SalesPlanAttachedFiles - A link to the selected attached file.
//  						 - CatalogRef.PlanOfGoodsStockAttachedFiles - A link to the selected attached file.
//  						 - CatalogRef.ProductionPlanAttachedFiles - A link to the selected attached file.
//  						 - CatalogRef.AssemblyDisassemblyPlanAttachedFiles - A link to the selected attached file.
//  						 - CatalogRef.SalesPlanByCategoriesAttachedFiles - A link to the selected attached file.
//  						 - CatalogRef.InventoryConsumptionPlanAttachedFiles - A link to the selected attached file.
//  DownloadOptionsFromExcel - Structure - Download parameters from Excel.
//
Procedure ImportFromExcel(Form, AttachedFile, DownloadOptionsFromExcel = Undefined) Export
	
	AdditionalParameters = FilesOperationsClientServer.FileDataParameters();
	AdditionalParameters.FormIdentifier = Form.UUID;
	
	FileData = ProcessingWithExcelServerCall.GetFileData(AttachedFile, AdditionalParameters);
	
	FileExtention = FileData["Extension"];
	If Lower(FileExtention) <> "xls"
		And Lower(FileExtention) <> "xlsx" Then
		ErrorMessage  = NStr("vi = 'Tệp không phải là tệp Excel, lựa chọn bị cấm.';
							|ru = 'Файл не является файлом формата Excel, выбор запрещен.';
							|en = 'File is not an Excel file. Selection is prohibited.'; fa = 'File is not an Excel file. Selection is prohibited.';
							|it = 'Il file non è in formato Excel, la selezione è vietata.';
							|pl = 'Plik nie jest plikiem Excel, wybór jest niedozwolony.';
							|tr = 'Dosya bir Excel dosyası değil, seçim yasak.'");
		
		ShowMessageBox(, ErrorMessage);
		Return;
		//Cause an error message exception;
	EndIf;
	
	AdditionalParameters = 
		New Structure("Form, AttachedFile, DownloadOptionsFromExcel", Form, AttachedFile, DownloadOptionsFromExcel);
		
	If Not FileData.CurrentUserEditsFile Then
		
		Notification = New CallbackDescription(
			"DownloadFromExcelGettingFile",
			ThisObject,
			AdditionalParameters);
		
		FilesOperationsClient.GetAttachedFile(
			Notification,
			AttachedFile,
			Form.UUID,
			New Structure("FileData, ForEditing", FileData, False));
		
	Else
		
		// No need to get the file to disk so as not to erase unsaved changes
		UserWorkingDirectory = FilesOperationsInternalClient.UserWorkingDirectory();
		TempFileName         = UserWorkingDirectory + FileData.RelativePath + FileData.FileName;
		
		DownloadFromExcelGettingFile(
			New Structure("ErrorDescription, FullFileName", "", TempFileName),
			AdditionalParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
// 	Result - DialogReturnCode - 
// 	AdditionalParameters - Structure - structure with mandatory Attributes:
//    * Form - ClientApplicationForm - required Attributes in the form:
//      ** Object - DocumentObject -
Procedure UploadToExcelExtensionEnabled(Result, AdditionalParameters) Export 
	
	Form 		 = AdditionalParameters.Form;
	Object 		 = Form.Object;
	
	If Form.Modified Or Not ValueIsFilled(Object.Ref) Then
		
		AdditionalParameters = New Structure("Form", Form);
		Notification = New CallbackDescription("UploadToExcelResponseProcessing", ThisObject, AdditionalParameters);
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại và tiếp tục';
												|ru = 'Записать и продолжить';
												|en = 'Save and continue'; fa = 'Save and continue';
												|it = 'Registrare e continuare';
												|pl = 'Zapisz i kontynuuj';
												|tr = 'Kaydet ve devam et'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification, 
			NStr("vi = 'Trước khi kết xuất cần ghi lại chứng từ. Thực hiện ghi lại chứng từ và tiếp tục?';
				|ru = 'Перед выгрузкой документ необходимо записать. Выполнить запись документа и продолжить?';
				|en = 'Save the document before exporting it. Save the document and continue?'; fa = 'Save the document before exporting it. Save the document and continue?';
				|it = 'Prima del download è necessario salvare il documento. Salvare il documento e continuare?';
				|pl = 'Przed eksportowaniem dokument należy zapisać. Zapisać dokument i kontynuować?';
				|tr = 'Belgeyi aktarmadan önce kaydetmeniz gerekmektedir. Belge kaydı gerçekleştirilsin ve devam edilsin mi?'"),
			Buttons);
		Return;
		
	EndIf;
	
	CreateAndProcessAttachedExcelFile(Form);
	
EndProcedure

// Parameters:
// 	Result - DialogReturnCode - 
// 	AdditionalParameters - Structure - structure with mandatory Attributes:
//    * Form - ClientApplicationForm, ManagedFormExtensionForObjects - 
Procedure UploadToExcelResponseProcessing(Result, AdditionalParameters) Export 
	
	Form = AdditionalParameters.Form;
	
	If Result = DialogReturnCode.Yes Then
		WriteParameters = New Structure;
		Form.NotificationAfterRecording = New CallbackDescription("UploadToExcelAfterRecording", ThisObject, AdditionalParameters);
		Form.Write();
		Return;
	EndIf;
	
EndProcedure

// Parameters:
// 	Result - DialogReturnCode - 
// 	AdditionalParameters - Structure - structure with mandatory Attributes:
//    * Form - ClientApplicationForm - required Attributes in the form:
//      ** Object - DocumentObject -
Procedure UploadToExcelAfterRecording(Result, AdditionalParameters) Export 
	
	Form = AdditionalParameters.Form;
	
	If Result <> True Or Not ValueIsFilled(Form.Object.Ref) Or Form.Modified Then
		Return;
	EndIf;
	
	CreateAndProcessAttachedExcelFile(Form);
	
EndProcedure


Procedure SelectAttachedExcelFileExtensionConnected(Result, AdditionalParameters) Export 
	
	FilesOperationsClient.OpenFileChoiceForm(
		AdditionalParameters.FilesOwner,
		AdditionalParameters.FormItem);
	
EndProcedure

// Parameters:
// 	Result - DialogReturnCode - 
// 	AdditionalParameters - Structure - structure with mandatory Attributes:
//    * Form - ClientApplicationForm, ManagedFormExtensionForObjects -
Procedure SelectAttachedExcelFileResponseProcessing(Result, AdditionalParameters) Export 
	
	Form = AdditionalParameters.Form;
	
	If Result = DialogReturnCode.Yes Then
		Form.NotificationAfterRecording = New CallbackDescription("SelectAttachedExcelFileAfterRecording", ThisObject, AdditionalParameters);
		
		Form.Write();
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Result - DialogReturnCode - 
// 	AdditionalParameters - Structure - structure with mandatory Attributes:
//    * Form - ClientApplicationForm - required Attributes in the form:
//      ** Object - DocumentObject -
Procedure SelectAttachedExcelFileAfterRecording(Result, AdditionalParameters) Export 
	
	Form = AdditionalParameters.Form;
	
	If Result <> True Or Not ValueIsFilled(Form.Object.Ref) Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"SelectAttachedExcelFileExtensionConnected",
		ThisObject,
		New Structure("FilesOwner, FormItem", Form.Object.Ref, Form.Items[AdditionalParameters.NameOfSelectionElement]));
	
	CommonClient.CheckFileSystemExtensionAttached(CallbackDescription);
	
EndProcedure


Procedure DownloadFromExcelGettingFile(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorDescription) Then
		Raise Result.ErrorDescription;
	EndIf;
	
	#If Not WebClient And Not MobileClient Then
	
	Try
		COMObject = New COMObject("Excel.Application");
		COMObject.AutomationSecurity = 3;
	Except
		ErrorMessage =
			NStr("vi = 'Không thể kết nhập đơn giá từ tệp Excel. 
				|Hãy chắc chắn là trong Server có cài đặt chương trình Microsoft Excel. 
				|Chi tiết:';
				|ru = 'Не удалось загрузить цены из файла Excel. 
				|Убедитесь, что на сервере установлена программа Microsoft Excel. 
				|Подробности:';
				|en = 'Cannot import prices from Excel file.
				|Make sure Microsoft Excel is installed on the server. 
				|Details:'; fa = 'Cannot import prices from Excel file.
				|Make sure Microsoft Excel is installed on the server. 
				|Details:';
				|it = 'Non è stato possibile caricare i prezzi dal file Excel. 
				|Verificare che sul server sia installato il programma Microsoft Excel. 
				|Dettagli:';
				|pl = 'Nie udało się pobrać ceny z pliku Excel. 
				|Upewnij się, że na serwerze jest zainstalowany program Microsoft Excel. 
				|Szczegóły:';
				|tr = 'Excel dosyasından fiyatlar yüklenemedi. 
				|Sunucuda Microsoft Excel''in kurulu olduğundan emin ol. 
				|Ayrıntılar:'") + "
				|" + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	TempFileName 		 = Result.FullFileName;
	Form 		 			 = AdditionalParameters.Form;
	AttachedFile 		 = AdditionalParameters.AttachedFile;
	DownloadOptionsFromExcel = AdditionalParameters.DownloadOptionsFromExcel;
	
	Try
		Workbook      = COMObject.Workbooks.Open(TempFileName);
		Sheet         = Workbook.Worksheets(1);
	Except
		COMObject.Quit();
		COMObject = 0;
		ErrorMessage = NStr("vi = 'Không thể đọc dữ liệu từ tệp. Chi tiết:';
							|ru = 'Не удалось прочитать данные из файла. Подробности:';
							|en = 'Cannot read data from the file. More information:'; fa = 'Cannot read data from the file. More information:';
							|it = 'Non è stato possibile leggere i dati dal file. Dettagli:';
							|pl = 'Nie udało się odczytać dane z pliku. Szczegóły:';
							|tr = 'Dosyadan veriler okunamadı. Ayrıntılar:'") + " "
		                    + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	MatchingComments = New Map;
	
	// Arrays of structures
	DownloadData  = New Array;
	
	ThereAreLinesAdded = False;
	
	// Data loading
	Try
		
		If DownloadOptionsFromExcel.Property("SearchColumns") Then
			SearchColumns = DownloadOptionsFromExcel.SearchColumns;
		Else
			TheStructureOfTheSearch = New Structure;
		EndIf;
		
		If DownloadOptionsFromExcel.Property("TheStructureOfTheSearch") Then
			TheStructureOfTheSearch = DownloadOptionsFromExcel.TheStructureOfTheSearch;
		Else
			TheStructureOfTheSearch = New Structure;
		EndIf;
		
		For ColumnNumber=1 To Sheet.Cells.SpecialCells(11).Column Do
		
			SearchKey = "";
			Value = Sheet.Cells(1, ColumnNumber).Value;
			If TypeOf(Value) = Type("String") Or TypeOf(Value) = Type("Number") Then
				If TypeOf(Value) = Type("Number") Then
					Value = Format(Value, "NG=0");
				EndIf; 
				SearchValue = TrimAll(Value);
				SearchColumn_ = SearchColumns.FindByValue(SearchValue);
				If SearchColumn_ <> Undefined Then
					SearchKey = SearchColumn_.Presentation;
				EndIf; 
			EndIf;
			If TypeOf(Value) = Type("Date") Or StrFind(SearchKey,"Period_") > 0 Then
				ColumnName = "";
				If StrFind(SearchKey,"Period_") > 0 Then
					ColumnName = StrReplace(SearchKey, "Period_", "");
					SearchKey = "";
				ElsIf DownloadOptionsFromExcel.Property("TimeIntervals") Then
					FoundRows = DownloadOptionsFromExcel.TimeIntervals.FindRows(New Structure("StartDate, Active_", Value, True));
					If FoundRows.Count() > 0 Then
						ColumnName = FoundRows[0].ColumnName;
					EndIf;
				EndIf; 
				
				If ValueIsFilled(ColumnName) And DownloadOptionsFromExcel.Property("PeriodAttributes") Then
					ColumnSuffix = 0;
					For Each PeriodAttribute In DownloadOptionsFromExcel.PeriodAttributes Do
						TheStructureOfTheSearch.Insert(PeriodAttribute+ColumnName, ColumnNumber+ ColumnSuffix);
						ColumnSuffix = ColumnSuffix + 1;
						If PeriodAttribute = "Count_" Then
							MatchingComments.Insert(ColumnNumber, "Comment_" + ColumnName);
						EndIf;
					EndDo; 
				EndIf; 
			EndIf; 
			
			If ValueIsFilled(SearchKey) Then
				TheStructureOfTheSearch.Insert(SearchKey, ColumnNumber);
			EndIf; 
			
			If Value = "Count" Then
				MatchingComments.Insert(ColumnNumber, "Comment");
			EndIf;
			
		EndDo; 
		
		If DownloadOptionsFromExcel.Property("DataStartLineNumber") Then
			LineNumber = DownloadOptionsFromExcel.DataStartLineNumber;
		Else
			LineNumber = 1;
		EndIf; 
		
		While LineNumber <= Sheet.Cells.SpecialCells(11).Row Do
			
			NewRow = New Structure("RowCode");
			
			For Each KeyValue In TheStructureOfTheSearch Do
				
				Value = Undefined;
				If KeyValue.Value > 0 Then
					
					Value = Sheet.Cells(LineNumber, KeyValue.Value).Value;
					If TypeOf(Value) = Type("String") 
						And (Find(KeyValue.Key,"Count") > 0
						Or StrFind(KeyValue.Key,"Price") > 0
						Or StrFind(KeyValue.Key,"Sum") > 0) Then
						
						Try
							Value = Number(Value);
						Except
							Value = Undefined;
						EndTry;
					ElsIf TypeOf(Value) = Type("String") 
						And StrFind(KeyValue.Key,"Date") > 0 Then
						
						Try
							// Conversion to date for a string of the format "dd.MM.yyyy"
							Value = Date(Right(Value,4) + Mid(Value,4,2) + Left(Value,2)); 
						Except
							Value = Undefined;
						EndTry;
						
					EndIf; 
					
				EndIf; 
				
				NewRow.Insert(KeyValue.Key, Value);
				
				CommentColumnName = MatchingComments.Get(KeyValue.Value);
				If CommentColumnName<>Undefined Then
					Comment = Sheet.Cells(LineNumber, KeyValue.Value).Comment;
					If Comment <> Undefined Then
						NewRow.Insert(CommentColumnName, Comment.Text());
					EndIf;
				EndIf;
				
			EndDo;
			
			DownloadData.Add(NewRow);
			
			LineNumber = LineNumber + 1;
				
		EndDo;
		
		Workbook.Close();
		
	Except
		COMObject.Quit();
		COMObject = 0;
		ErrorMessage = NStr("vi = 'Không thể đọc dữ liệu từ tệp. Chi tiết:';
							|ru = 'Не удалось прочитать данные из файла. Подробности:';
							|en = 'Cannot read data from the file. More information:'; fa = 'Cannot read data from the file. More information:';
							|it = 'Non è stato possibile leggere i dati dal file. Dettagli:';
							|pl = 'Nie udało się odczytać dane z pliku. Szczegóły:';
							|tr = 'Dosyadan veriler okunamadı. Ayrıntılar:'") + " "
		                    + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	COMObject.Quit();
	COMObject = 0;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("DownloadData", DownloadData);
	ReturnStructure.Insert("FormUniqueID", AdditionalParameters.Form.UUID);
	Notify("WorkingWithExcelClient_DownloadFromExcel", ReturnStructure);
	
	#EndIf
	
EndProcedure


Procedure CreateAndProcessAttachedExcelFile(Form)
	
	Information = ProcessingWithExcelServerCall.CreateAttachedExcelFile(Form.Object.Ref, Form.UUID);
	If Information = Undefined Then
		ErrorMessage = NStr("vi = 'Không thể kết xuất chứng từ ra Excel.';
							|ru = 'Не удалось выгрузить документ в Excel.';
							|en = 'Cannot export the document to Excel.'; fa = 'Cannot export the document to Excel.';
							|it = 'Non è stato possibile caricare il documento su Excel.';
							|pl = 'Nie udało się przesłać dokument w Excel.';
							|tr = 'Belge Excel''e yüklenemedi.'");
		Raise ErrorMessage;
	EndIf;
	
	If Not Information.Property("ExcelActionStructure")
	 Or Not ValueIsFilled(Information.ExcelActionStructure) Then
		Return;
	EndIf;
	
	AdditionalParameters =
		New Structure("Form, Information", Form, Information);
	
	Notification = New CallbackDescription(
		"CreateAndProcessAttachedExcelFileRetrieveFile",
		ThisObject,
		AdditionalParameters);
	
	FilesOperationsClient.GetAttachedFile(
		Notification,
		Information.File,
		Form.UUID,
		New Structure("FileData, ForEditing", Information.FileData, True));
		
EndProcedure

Procedure CreateAndProcessAttachedExcelFileRetrieveFile(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorDescription) Then
		Raise Result.ErrorDescription;
	EndIf;
	
	#If Not WebClient And Not MobileClient Then
		
	Try
		COMObject = New COMObject("Excel.Application");
		COMObject.AutomationSecurity = 3;
	Except
		ErrorMessage =
			NStr("vi = 'Không thể kết xuất chứng từ vào Excel.
				|Hãy chắc chắn rằng, trong máy tính có cài đặt chương trình Microsoft Excel.
				|Chi tiết:';
				|ru = 'Не удалось выгрузить документ в Excel.
				|Убедитесь, что на компьютере установлена программа Microsoft Excel.
				|Подробности:';
				|en = 'Cannot export document to Excel.
				|Make sure Microsoft Excel is installed on your computer.
				|More information:'; fa = 'Cannot export document to Excel.
				|Make sure Microsoft Excel is installed on your computer.
				|More information:';
				|it = 'Non è stato possibile caricare i prezzi su Excel. 
				| Verificare che il programma sia installato sul computer. 
				| Dettagli:';
				|pl = 'Nie udało się przesłać dokument w Excel.
				|Upewnij się, że na komputerze jest zainstalowany program Microsoft Excel.
				|Szczegóły:';
				|tr = 'Belge Excel''e yüklenemedi.
				|Bilgisayarınızda Microsoft Excel''in yüklü olduğundan emin ol.
				|Ayrıntılar:'") + "
				|" + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	#EndIf
	
	TempFileName 	= Result.FullFileName;
	Form 		 		= AdditionalParameters.Form;
	Information   		= AdditionalParameters.Information;
	
	Try
		
	#If Not WebClient And Not MobileClient Then
		
		Workbook = COMObject.Workbooks.Open(TempFileName);
		Sheet = Workbook.Worksheets(1);
		
		ExcelActionStructure = Information.ExcelActionStructure;
		
		If ExcelActionStructure.Property("AutoFilter") Then
			
			AutoFilter = ExcelActionStructure.AutoFilter;
			
			// Installing an autofilter on price columns
			Sheet.Range(Sheet.Cells(AutoFilter.RowStart1, AutoFilter.ColumnStart1), Sheet.Cells(AutoFilter.RowStart1, Sheet.Cells.SpecialCells(11).Column)).AutoFilter();
		
		EndIf;
		
		If ExcelActionStructure.Property("HiddenColumns") Then
			// Hiding columns 
			For Each ColumnNumber In ExcelActionStructure.HiddenColumns Do
				Sheet.Columns(ColumnNumber).Hidden = True;
			EndDo; 
		EndIf;
		
		Workbook.Save();
		Workbook.Close();
		
		COMObject.Quit();
		COMObject = 0;
		
	#EndIf
		
		Notification = New CallbackDescription(
			"CreateAndProcessAttachedExcelFileFromFile",
			ThisObject,
			AdditionalParameters);
		
		FilesOperationsClient.PutAttachedFile(
			Notification,
			Information.File,
			Form.UUID);
		
	Except
		#If Not WebClient And Not MobileClient Then
		COMObject.Quit();
		COMObject = 0;
		#EndIf
		
		ErrorMessage = NStr("vi = 'Không thể ghi lại dữ liệu vào tệp. Chi tiết:';
							|ru = 'Не удалось записать данные в файл. Подробности:';
							|en = 'Cannot save data to file. More information:'; fa = 'Cannot save data to file. More information:';
							|it = 'Non è stato possibile registrare i dati nel file. Dettagli:';
							|pl = 'Nie udało się zapisać danych do pliku. Szczegóły:';
							|tr = 'Dosyaya veriler kaydedilmedi. Ayrıntılar:'") + "
			|" + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
		
	EndTry;
	
EndProcedure

Procedure CreateAndProcessAttachedExcelFileFromFile(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorDescription) Then
		Raise Result.ErrorDescription;
	EndIf;
	
	Information = AdditionalParameters.Information;
	
	FilesOperationsClient.OpenFileForm(Information.File);
	
EndProcedure

#EndRegion
