///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core") Then
		Items.ExportDirectory.ChoiceButton = False;
		SSLAvailable = False;
	Else
		SSLAvailable = True;
	EndIf;
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectExportDirectorySuggested(FileSystemExtensionAttached1, AdditionalParameters) Export
	
	If FileSystemExtensionAttached1 Then
		
		SelectingFile = New FileDialog(FileDialogMode.ChooseDirectory);
		SelectingFile.Multiselect = False;
		SelectingFile.Title = NStr("vi = 'Chọn thư mục kết xuất';
									|ru = 'Выбор каталога экспорта';
									|en = 'Select export directory'; fa = 'Select export directory';
									|it = 'Seleziona della directory dell''esportazione';
									|pl = 'Wybór katalogu eksportu';
									|tr = 'Dışa aktarım dizini seç'");
		
		CallbackDescription = New CallbackDescription("SelectDirectoryDialogCompletion", ThisObject, Undefined);
		If SSLAvailable Then 
			ModuleFileSystemClient = Eval("FileSystemClient");
			If TypeOf(ModuleFileSystemClient) = Type("CommonModule") Then
				ModuleFileSystemClient.ShowSelectionDialog(CallbackDescription, SelectingFile);
			EndIf;
		Else
			SelectingFile.Show(CallbackDescription);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	If SSLAvailable Then
		CallbackDescription = New CallbackDescription("SelectExportDirectorySuggested", ThisObject);
		ModuleFileSystemClient = Eval("FileSystemClient");
		If TypeOf(ModuleFileSystemClient) = Type("CommonModule") Then
			ModuleFileSystemClient.Attach1CEnterpriseExtension(CallbackDescription);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExportPerformanceTestFile(Command)
    
    HasErrors = False;
    
    If Not ValueIsFilled(ExportPeriodStartDate) Then
        
        UserMessage = New UserMessage;
        UserMessage.Field = "ExportPeriodStartDate";
        UserMessage.Text = NStr("vi = 'Giá trị tham số ""Ngày bắt đầu"" chưa điền.
			|Không thể kết xuất.';
			|ru = 'Значение параметра ""Дата начала"" не заполнено.
			|Экспорт невозможен.';
			|en = 'Start date is required.
			|Cannot export.'; fa = 'Start date is required.
			|Cannot export.';
			|it = 'Il valore di prametro ""Data di inizio"" non è compilato.
			|L''esportazione non è possibile.';
			|pl = 'Wartość parametru ""Data rozpoczęcia"" nie zostało wypełnione.
			|Eksport nie jest możliwy.';
			|tr = '""Başlangıç tarihi"" parametre değeri doldurulmadı.
			|Dışa aktarım imkansız.'");
        UserMessage.Message();
        
        HasErrors = True;
        
    EndIf;
    
    If Not ValueIsFilled(ExportPeriodEndDate) Then
        
        UserMessage = New UserMessage;
        UserMessage.Field = "ExportPeriodEndDate";
        UserMessage.Text = NStr("vi = 'Giá trị tham số ""Ngày kết thúc"" chưa điền.
			|Không thể kết xuất.';
			|ru = 'Значение параметра ""Дата окончания"" не заполнено.
			|Экспорт невозможен.';
			|en = 'End date is required.
			|Cannot export.'; fa = 'End date is required.
			|Cannot export.';
			|it = 'Il valore di parametro ""Data di fine"" non è compilato.
			|L''esportazione non è possibile.';
			|pl = 'Wartość parametru ""Data zakończenia"" nie zostało wypełnione.
			|Eksport nie jest możliwy.';
			|tr = '""Başlangıç tarihi"" parametre değeri doldurulmadı.
			|Dışa aktarım imkansız.'");
        UserMessage.Message();
        
        HasErrors = True;
        
    EndIf;
    
    If Not ValueIsFilled(ExportDirectory) Then
        
        UserMessage = New UserMessage;
        UserMessage.Field = "ExportDirectory";
        UserMessage.Text = NStr("vi = 'Giá trị tham số ""Thư mục kết xuất"" chưa điền.
			|Không thể kết xuất.';
			|ru = 'Значение параметра ""Каталог экспорта"" не заполнено.
			|Экспорт невозможен.';
			|en = 'Export directory is required.
			|Cannot export.'; fa = 'Export directory is required.
			|Cannot export.';
			|it = 'Il valore di parametro ""Directory di esportazione"" non è compilato.
			|L''esportazione non è possibile.';
			|pl = 'Wartość parametru ""Katalog eksportu"" nie zostało wypełnione.
			|Eksport nie jest możliwy.';
			|tr = '""Dışa aktarım dizini"" parametresinin değeri doldurulmadı.
			|Dışa aktarım imkansız.'");
        UserMessage.Message();
        
        HasErrors = True;
        
    EndIf;
    
     If Not ValueIsFilled(ArchiveName) Then
        
        UserMessage = New UserMessage;
        UserMessage.Field = "ArchiveName";
        UserMessage.Text = NStr("vi = 'Giá trị tham số ""Tên lưu trữ"" chưa điền.
			|Không thể kết xuất.';
			|ru = 'Значение параметра ""Имя архива"" не заполнено.
			|Экспорт невозможен.';
			|en = 'Archive name is required.
			|Cannot export.'; fa = 'Archive name is required.
			|Cannot export.';
			|it = 'Il valore di parametro ""Nome dell''archivio"" non è compilato.
			|L''esportazione non è possibile.';
			|pl = 'Wartość parametru ""Nazwa archiwum"" nie zostało wypełnione.
			|Eksport nie jest możliwy.';
			|tr = '""Arşiv adı"" parametresinin değeri doldurulmadı.
			|Dışa aktarım imkansız.'");
        UserMessage.Message();
        
        HasErrors = True;
        
    EndIf;
        
    If ValueIsFilled(ExportPeriodStartDate) And ValueIsFilled(ExportPeriodEndDate) And ExportPeriodStartDate >= ExportPeriodEndDate Then
        
        UserMessage = New UserMessage;
        UserMessage.Field = "ExportPeriodStartDate";
        UserMessage.Text = NStr("vi = 'Giá trị tham số ""Ngày bắt đầu"" lới hơn hoặc bằng giá trị tham số ""Ngày kết thúc"".
			|Không thể kết xuất.';
			|ru = 'Значение параметра ""Дата начала"" больше или равно значения параметры ""Дата окончания"".
			|Экспорт невозможен.';
			|en = 'End date must be greater than Start date.
			|Cannot export.'; fa = 'End date must be greater than Start date.
			|Cannot export.';
			|it = 'Il valore di parametro ""Data di inizio"" di più o pati al valore del parametro ""Data di fine"".
			|L''esportazione non è possibile.';
			|pl = 'Wartość parametru ""Data rozpoczęcia"" jest większa lub równa wartości parametru ""Data zakończenia"".
			|Eksport nie jest możliwy.';
			|tr = '""Başlangıç tarihi"" parametresinin değeri, ""Bitiş tarihi"" parametresinin değerinden büyük veya eşit.
			|Dışa aktarım imkansız.'");
        UserMessage.Message();
        
        HasErrors = True;
        
    EndIf;
    
    If HasErrors Then
        Return;
    EndIf;
            
	StorageAddress = PutToTempStorage(Undefined, UUID);
	ExportParameters1 = New Structure;
	ExportParameters1.Insert("StartDate", ExportPeriodStartDate);
	ExportParameters1.Insert("EndDate", ExportPeriodEndDate);
	ExportParameters1.Insert("StorageAddress", StorageAddress);
	ExportParameters1.Insert("Profile", Profile);
	RunExportAtServer(ExportParameters1);
	
	BinaryData = GetFromTempStorage(StorageAddress); // BinaryData
	DeleteFromTempStorage(StorageAddress);
    
    If BinaryData <> Undefined Then
        BinaryData.Write(ExportDirectory + GetClientPathSeparator() + ArchiveName + ".zip");
    Else
        UserMessage = New UserMessage;
        UserMessage.Text = NStr("vi = 'Trong kỳ đã chỉ ra không có sự đo lường. Chưa tạo tệp lưu trữ.';
								|ru = 'За указанный период нет замеров. Файл архива не сформирован.';
								|en = 'There are no samples for the period. The archive was not generated.'; fa = 'There are no samples for the period. The archive was not generated.';
								|it = 'Durante questo periodo non ci sono rilevazioni. Il file di archivio non è formato.';
								|pl = 'Za wskazany okres nie pomiarów. Plik archiwum nie został wygenerowany.';
								|tr = 'Belirtilen dönem içerisinde herhangi bir ölçüm yoktur. Arşiv dosyası oluşturulmadı.'") + Chars.LF;
        UserMessage.Message();
    EndIf;
    	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure RunExportAtServer(Parameters)
	PerformanceMonitor.PerformanceMonitorDataExport(Undefined, Parameters);	
EndProcedure

&AtClient
Procedure SelectDirectoryDialogCompletion(SelectedFiles, AdditionalParameters) Export
    
    If SelectedFiles <> Undefined Then
		ExportDirectory = SelectedFiles[0];
	EndIf;
		
EndProcedure


#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
