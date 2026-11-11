
#Region FormEventHandlers 

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ServerAddress = AnalyticsSystem.GetAnalyticsSystemServerAddress(); 
	DownloadAdditionalSources();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Source = ThisObject And EventName = "DownloadAdditionalSource" Then
		DownloadAdditionalSource(Parameter);
	EndIf;

EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersAdditionalSources

&AtClient
Procedure AdditionalSourcesBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	ServerFormat = CheckFormatVersionOfAdditionalServerSources();
	
	Cancel = True;
	If Copy Then 
		SourceParameters = New Structure();
		SourceParameters.Insert("Name", CreateNameForAdditionalSource(Item.CurrentData.Name));
		SourceParameters.Insert("Id", Item.CurrentData.Id);
		SourceParameters.Insert("Copy", True);
		SourceParameters.Insert("FormIdentifier", String(New UUID()));
		SourceParameters.Insert("ExistingNames", NamesOfAdditionalSources());
		SourceParameters.Insert("ServerFormat", ServerFormat);
		
		OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.AdditionalSource", SourceParameters, ThisObject, SourceParameters["FormIdentifier"],,,,
		FormWindowOpeningMode.Independent);
	EndIf; 
	
EndProcedure

&AtClient
Procedure AdditionalSourcesBeforeRowChange(Item, Cancel)
	
	ServerFormat = CheckFormatVersionOfAdditionalServerSources();
	
	Cancel = True;
	FormParameters = New Structure();
	FormParameters.Insert("Id", Item.CurrentData.Id);
	FormParameters.Insert("FormIdentifier", Item.CurrentData.Id);
	FormParameters.Insert("ExistingNames", NamesOfAdditionalSources(Item.CurrentData.Name));
	FormParameters.Insert("ServerFormat", ServerFormat);
	
	OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.AdditionalSource", FormParameters, ThisObject, FormParameters["FormIdentifier"],,,,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure AdditionalSourcesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	Notification = New CallbackDescription("AdditionalSourcesAfterConfirmationOfDeletion", ThisObject, Item.CurrentData.Id);
	ShowQueryBox(Notification,
	StrTemplate(NStr("vi = 'Xóa ''%1''?';
					|ru = 'Удалить ''%1''?';
					|en = 'Delete %1?'; fa = 'Delete %1?';
					|it = 'Удалить ''%1''?';
					|pl = 'Delete %1?';
					|tr = '''%1'' silinsin mi?'"), Item.CurrentData.Name),
	QuestionDialogMode.YesNo); 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region AdditionalSources

&AtClient
Async Procedure AdditionalSourcesDownloadFromFile(Command)
	
	Dialog = New PutFilesDialogParameters();
	Dialog.MultipleChoice = False;
	Dialog.Filter = NStr("vi = 'Tệp Json';
						|ru = 'Json-файл';
						|en = 'Json file'; fa = 'Json file';
						|it = 'Json-файл';
						|pl = 'Json file';
						|tr = 'Json dosyası'") + " (*.json)|*.json";
	
	FileDetails = Await PutFileToServerAsync(, , , Dialog);
	
	If FileDetails <> Undefined Then
		Content = ContentsOfTemporaryFile(FileDetails.Address);
		SourcesStructure = AdditionalSourcesToDownload(Content);
		
		If SourcesStructure.MatchingNamesArray.Count() Then
			QueryText = NStr("vi = 'Các nguồn bổ sung sẽ bị ghi đè:';
							|ru = 'Дополнительные источники будут перезаписаны:';
							|en = 'Additional sources will be overwritten:'; fa = 'Additional sources will be overwritten:';
							|it = 'Дополнительные источники будут перезаписаны:';
							|pl = 'Additional sources will be overwritten:';
							|tr = 'Ek kaynaklar yeniden kaydedilecektir:'")
			+ Chars.LF + StrConcat(SourcesStructure.MatchingNamesArray, Chars.LF);
			
			Notification = New CallbackDescription("AfterConfirmingOverwritingOfAdditionalSources", ThisObject, SourcesStructure.AdditionalSourcesArray);
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.OKCancel, 0, DialogReturnCode.Cancel);
		Else
			AfterConfirmingOverwritingOfAdditionalSources(DialogReturnCode.OK, SourcesStructure.AdditionalSourcesArray);
		EndIf;
	EndIf;
	
EndProcedure 

&AtClient
Procedure AdditionalSourcesUpdateList(Command)
	
	DownloadAdditionalSources();
	
EndProcedure

&AtClient
Procedure AdditionalSourcesSaveEverythingToFile(Command)
	
	CheckFormatVersionOfAdditionalServerSources();
	SaveAdditionalSourcesToFile(); 
	
EndProcedure  

&AtClient
Procedure AdditionalSourcesSaveSelectedToFile(Command)
	
	CheckFormatVersionOfAdditionalServerSources();
	SaveAdditionalSourcesToFile(True);
	
EndProcedure 

&AtClient
Procedure CreateAdditionalSource(Command)
	
	ServerFormat = CheckFormatVersionOfAdditionalServerSources();
	
	FormParameters = New Structure();
	FormParameters.Insert("Name", CreateNameForAdditionalSource());
	FormParameters.Insert("FormIdentifier", String(New UUID()));
	FormParameters.Insert("ExistingNames", NamesOfAdditionalSources());
	FormParameters.Insert("ServerFormat", ServerFormat);
	
	OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.AdditionalSource", FormParameters, ThisObject, FormParameters["FormIdentifier"],,,,
	FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region AdditionalSources

&AtServer
Procedure DownloadAdditionalSource(SourceIdentificator = Undefined)
	
	DownloadAdditionalSources();
	If SourceIdentificator <> Undefined Then
		For Each Source In AdditionalSources Do
			If Source.Id = SourceIdentificator Then
				Items.AdditionalSources.CurrentRow = Source.GetID();
				Break;
			EndIf;
		EndDo; 
	EndIf;
	
EndProcedure

&AtServer
Procedure DownloadAdditionalSources()
	
	AdditionalSources.Clear();
	
	Sources = DataProcessors.Manage1CAnalyticsPanels.AdditionalSourcesFromScheme();
	
	For Each Source In Sources Do
		NewRow = AdditionalSources.Add();
		NewRow.Id = Source.Get("id");
		Try
			Source_Data = JSONValue(Source.Get("data"));
		Except
			Source_Data = New Map();
		EndTry;
		NewRow.Name = UndefinedInEmptyLine(Source_Data.Get("name"));
		NewRow.Presentation = UndefinedInEmptyLine(Source_Data.Get("synonym"));
		NewRow.Data = Source.Get("data");
		NewRow.Version = Source.Get("version");
	EndDo;
	AdditionalSources.Sort("Name");
	
EndProcedure

&AtClientAtServerNoContext
Function UndefinedInEmptyLine(Value) 
	
	Return ?(Value = Undefined, "", Value); 
	
EndFunction

&AtClient
Function NamesOfAdditionalSources(CurrentName = "")
	
	Names = New ValueList();
	For Each String In AdditionalSources Do
		If String.Name = CurrentName Then
			Continue;
		EndIf;
		Names.Add(String.Name);
	EndDo;
	Return Names;
	
EndFunction

&AtClient
Procedure AdditionalSourcesAfterConfirmationOfDeletion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		RemoveAdditionalSource(Var_Parameters);
	EndIf; 
	
EndProcedure

&AtServer
Procedure RemoveAdditionalSource(SourceIdentificator)
	
	DataProcessors.Manage1CAnalyticsPanels.DeleteSchema(SourceIdentificator);
	
	DownloadAdditionalSources();
	
EndProcedure

&AtClient
Function CreateNameForAdditionalSource(Val Prefix = Undefined)
	
	If Prefix <> Undefined Then
		While StrLen(Prefix) > 0 Do
			If CharCode(Prefix, StrLen(Prefix)) >= 48 And CharCode(Prefix, StrLen(Prefix)) <= 57 Then  
				Prefix = Left(Prefix, StrLen(Prefix)-1);
			Else
				Break;
			EndIf;
		EndDo;
		If StrLen(Prefix) = 0 Then
			Prefix = Undefined;
		EndIf;
	EndIf;
	If Prefix = Undefined Then
		Prefix = NStr("vi = 'Nguồn';
						|ru = 'Источник';
						|en = 'Source'; fa = 'منبع';
						|it = 'Источник';
						|pl = 'Source';
						|tr = 'Kaynak'");
	EndIf;
	Indus = 0;
	For Each String In AdditionalSources Do
		If StrStartsWith(String.Name, Prefix) Then
			Try
				CurIndex = Number(Mid(String.Name, StrLen(Prefix)+1));
			Except
				CurIndex = 0;
			EndTry;
			If CurIndex > Indus Then
				Indus = CurIndex;
			EndIf;
		EndIf;
	EndDo;
	Return Prefix + Format(Indus+1, "NG=");
	
EndFunction

&AtServer
Function CheckFormatVersionOfAdditionalServerSources()
	
	ServerFormat = ServerFormatVersion("additional-datasource");
	If ServerFormat = -1 Then 
		Raise NStr("vi = 'Không thể xác định phiên bản định dạng nguồn bổ sung, do server 1C:Analytics hỗ trợ. Hãy kiểm tra địa chỉ và tính khả dụng của server.';
					|ru = 'Не удалось определить версию формата дополнительных источников, поддерживаемую сервером 1С:Аналитики. Проверьте адрес и доступность сервера.';
					|en = 'Cannot determine the version of the additional source format supported by the 1C:Analytics server. Check the address and the server availability.'; fa = 'Cannot determine the version of the additional source format supported by the 1C:Analytics server. Check the address and the server availability.';
					|it = 'Не удалось определить версию формата дополнительных источников, поддерживаемую сервером 1С:Аналитики. Проверьте адрес и доступность сервера.';
					|pl = 'Cannot determine the version of the additional source format supported by the 1C:Analytics server. Check the address and the server availability.';
					|tr = '1C:Analytics sunucusu tarafından desteklenen ek kaynak formatının sürümü belirlenemedi. Sunucunun adresini ve kullanılabilirliğini kontrol edin.'");
	ElsIf ServerFormat > 2 Then 
		Raise NStr("vi = 'Phiên bản định dạng nguồn bổ sung của server 1C:Analytics cao hơn phiên bản do bộ xử lý hỗ trợ. Hãy cập nhật nền tảng 1C:Enterprise';
					|ru = 'Версия формата дополнительных источников сервера 1C:Аналитики выше версии, поддерживаемой обработкой. Обновите платформу 1С:Предприятие';
					|en = 'The additional source format version of the 1C:Analytics server is later than the version supported by the data processor. Update the 1C:Enterprise platform'; fa = 'The additional source format version of the 1C:Analytics server is later than the version supported by the data processor. Update the 1C:Enterprise platform';
					|it = 'Версия формата дополнительных источников сервера 1C:Аналитики выше версии, поддерживаемой обработкой. Обновите платформу 1С:Предприятие';
					|pl = 'The additional source format version of the 1C:Analytics server is later than the version supported by the data processor. Update the 1C:Enterprise platform';
					|tr = '1C:Analytics sunucusunun ek kaynaklarının format sürümü, işlem tarafından desteklenen sürümden daha yüksektir. 1C:Enterprise platformunu güncelleyin'");
	EndIf;
	Return ServerFormat;
	
EndFunction

&AtClient
Async Procedure SaveAdditionalSourcesToFile(OnlySelectedOnes = False)
	
	Data = AdditionalJSONSources(OnlySelectedOnes);
	Address = PutToTempStorage(Data); 
	
	Title = NStr("vi = 'Lưu tệp nguồn bổ sung';
				|ru = 'Сохранение файла дополнительных источников';
				|en = 'Save the additional source file'; fa = 'Save the additional source file';
				|it = 'Сохранение файла дополнительных источников';
				|pl = 'Save the additional source file';
				|tr = 'Ek kaynak dosyasının kaydedilmesi'");
	DialogForReceivingFiles = New GetFilesDialogParameters(Title, False);
	
	Await GetFileFromServerAsync(Address, "additional_datasources.json", DialogForReceivingFiles);
	
EndProcedure

&AtServer
Function AdditionalJSONSources(OnlySelectedOnes)
	
	If OnlySelectedOnes Then
		SelectedSources = New Array();
		SelectedIdLines = Items.AdditionalSources.SelectedRows;
		For Each ID In SelectedIdLines Do
			SelectedSources.Add(AdditionalSources.FindByID(ID));
		EndDo;
	Else
		SelectedSources = AdditionalSources;
	EndIf;
	
	SourcesArray = New Array();
	
	For Each String In SelectedSources Do
		Item = New Map();
		Item.Insert("type", "additional-datasource");
		Item.Insert("id", String.Id);
		Item.Insert("data", String.Data);
		Item.Insert("owner", "");
		If String.Version >= 2 Then
			Item.Insert("version", String.Version);
		EndIf;
		
		SourcesArray.Add(Item);
	EndDo;
	
	Return ValueToJSON(SourcesArray);
	
EndFunction

&AtServerNoContext
Function ContentsOfTemporaryFile(Address)
	
	TempFileName = GetTempFileName();
	Data = GetFromTempStorage(Address); //BinaryData
	Data.Write(TempFileName);
	
	NewTextDocument = New TextDocument();
	NewTextDocument.Read(TempFileName, TextEncoding.UTF8);
	Content = NewTextDocument.GetText();
	
	DeleteFromTempStorage(Address);
	DeleteFiles(TempFileName);
	
	Return Content;
	
EndFunction

&AtServer
Function AdditionalSourcesToDownload(Content)
	
	ServerFormat = ServerFormatVersion("additional-datasource");
	If ServerFormat = -1 Then 
		Raise NStr("vi = 'Không thể xác định phiên bản định dạng nguồn bổ sung, do server 1C:Analytics hỗ trợ. Hãy kiểm tra địa chỉ và tính khả dụng của server.';
					|ru = 'Не удалось определить версию формата дополнительных источников, поддерживаемую сервером 1С:Аналитики. Проверьте адрес и доступность сервера.';
					|en = 'Cannot determine the version of the additional source format supported by the 1C:Analytics server. Check the address and the server availability.'; fa = 'Cannot determine the version of the additional source format supported by the 1C:Analytics server. Check the address and the server availability.';
					|it = 'Не удалось определить версию формата дополнительных источников, поддерживаемую сервером 1С:Аналитики. Проверьте адрес и доступность сервера.';
					|pl = 'Cannot determine the version of the additional source format supported by the 1C:Analytics server. Check the address and the server availability.';
					|tr = '1C:Analytics sunucusu tarafından desteklenen ek kaynak formatının sürümü belirlenemedi. Sunucunun adresini ve kullanılabilirliğini kontrol edin.'");
	EndIf;
	
	Result = New Structure("AdditionalSourcesArray, MatchingNamesArray", New Array(), New Array());
	
	DownloadAdditionalSources();
	
	SourcesArray = JSONValue(Content);
	
	For Each Source In SourcesArray Do
		Source_Type = Source.Get("type");
		SourceFormat = Source.Get("version");
		If SourceFormat = Undefined Then
			SourceFormat = 1;
		EndIf;
		
		SourceID = Source.Get("id");
		
		If Source_Type <> "additional-datasource" Then
			Raise NStr("vi = 'Tệp được chọn không phải là tệp dữ liệu nguồn bổ sung';
						|ru = 'Выбранный файл не является файлом данных дополнительных источников';
						|en = 'The selected file is not an additional source data file'; fa = 'The selected file is not an additional source data file';
						|it = 'Выбранный файл не является файлом данных дополнительных источников';
						|pl = 'The selected file is not an additional source data file';
						|tr = 'Seçilen dosya ek kaynaklara ait bir veri dosyası değildir'");
		EndIf;
		
		If SourceFormat = 2 And ServerFormat < 2 Then
			Raise NStr("vi = 'Phiên bản định dạng nguồn bổ sung trong tệp cao hơn phiên bản do server 1C:Analytics hỗ trợ. Hãy cập nhật phiên bản server 1C:Analytics.';
						|ru = 'Версия формата дополнительных источников в файле выше версии, поддерживаемой сервером 1С:Аналитики. Обновите версию сервера 1С:Аналитики.';
						|en = 'The additional source format version in the file is later than the version supported by the 1C:Analytics server. Update the 1C:Analytics server version.'; fa = 'The additional source format version in the file is later than the version supported by the 1C:Analytics server. Update the 1C:Analytics server version.';
						|it = 'Версия формата дополнительных источников в файле выше версии, поддерживаемой сервером 1С:Аналитики. Обновите версию сервера 1С:Аналитики.';
						|pl = 'The additional source format version in the file is later than the version supported by the 1C:Analytics server. Update the 1C:Analytics server version.';
						|tr = 'Dosyadaki ek kaynakların format sürümü, 1C:Analytics sunucusu tarafından desteklenen sürümden daha yüksektir. 1C:Analytics sunucusunun sürümünü güncelleyin.'");
		EndIf;
		
		If SourceFormat > 2 Then
			Raise NStr("vi = 'Phiên bản định dạng nguồn bổ sung của tệp cao hơn phiên bản do bộ xử lý hỗ trợ. Hãy cập nhật nền tảng 1C:Enterprise.';
						|ru = 'Версия формата дополнительных источников файла выше версии, поддерживаемой обработкой. Обновите платформу 1С:Предприятие.';
						|en = 'The additional source format version of the file is later than the version supported by the data processor. Update the 1C:Enterprise platform.'; fa = 'The additional source format version of the file is later than the version supported by the data processor. Update the 1C:Enterprise platform.';
						|it = 'Версия формата дополнительных источников файла выше версии, поддерживаемой обработкой. Обновите платформу 1С:Предприятие.';
						|pl = 'The additional source format version of the file is later than the version supported by the data processor. Update the 1C:Enterprise platform.';
						|tr = 'Ek dosya kaynaklarının format sürümü, işlem tarafından desteklenen sürümden daha yüksektir. 1C:Enterprise platformunu güncelleyin.'");
		EndIf;
		
		AdditionalSource = New Map();
		AdditionalSource.Insert("type", Source_Type);
		AdditionalSource.Insert("data", Source.Get("data"));
		AdditionalSource.Insert("owner", "");
		AdditionalSource.Insert("id", SourceID);
		If SourceFormat <> 1 Then 
			AdditionalSource.Insert("version", SourceFormat);
		EndIf;
		
		Try
			Source_Data = JSONValue(Source.Get("data"));
		Except
			Source_Data = New Map();
		EndTry;
		
		Source_Name = UndefinedInEmptyLine(Source_Data.Get("name"));
		
		NameExists = False;
		For Each String In AdditionalSources Do
			If String.Name = Source_Name Then
				Result.MatchingNamesArray.Add(Source_Name);
				AdditionalSource.Insert("id", String.Id);
				NameExists = True;
				Break;
			EndIf;
		EndDo;
		
		If Not NameExists Then
			For Each String In AdditionalSources Do
				If String.Id = SourceID Then
					AdditionalSource.Insert("id", String(New UUID()));
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		Result.AdditionalSourcesArray.Add(AdditionalSource);
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure AfterConfirmingOverwritingOfAdditionalSources(Result, AdditionalSourcesArray) Export
	
	If Result = DialogReturnCode.OK Then
		RecordAdditionalSources(AdditionalSourcesArray);
	EndIf;
	
EndProcedure

&AtServer
Procedure RecordAdditionalSources(AdditionalSourcesArray)
	
	For Each Source In AdditionalSourcesArray Do
		JSONSource = ValueToJSON(Source);
		DataProcessors.Manage1CAnalyticsPanels.WriteSchema(JSONSource);
	EndDo;
	
	DownloadAdditionalSources();
	
EndProcedure

&AtServer
Function ServerFormatVersion(ObjectType)
	
	Return DataProcessors.Manage1CAnalyticsPanels.ServerFormatVersions(ServerAddress).Get(ObjectType);
	
EndFunction

#EndRegion

&AtServerNoContext
Function JSONValue(JSONString)
	
	If JSONString = "" Then
		Return New Array();
	EndIf;
	JSONReader = New JSONReader();
	JSONReader.SetString(JSONString);
	Return ReadJSON(JSONReader, True);
	
EndFunction

&AtServerNoContext
Function ValueToJSON(Value)
	
	JSONWriter = New JSONWriter();
	JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(JSONWriter, Value);
	
	Return JSONWriter.Close(); 
	
EndFunction 

#EndRegion
