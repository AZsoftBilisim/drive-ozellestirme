
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Constants.MonthEndClosingSettings.ProcessDataSetConstantsShipmentWithoutPPP";
	Handler.Version = "11.5.26.4";
	Handler.ExecutionMode = "Seamless";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Id = New UUID("1d233800-6888-4148-8c8f-487614db0751");
	Handler.ExecuteInMasterNodeOnly = True;
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment =
		NStr("vi = 'Điền tùy chỉnh kết chuyển cuối tháng với kiểu danh mục ""Giao dịch kết chuyển cuối tháng""';
			|ru = 'Заполняет настройки закрытия месяца с типом справочник ""Операции закрытия месяца""';
			|en = 'Fills in the month-end closing settings with the ""Month-end closing operations"" catalog type'; fa = 'Fills in the month-end closing settings with the ""Month-end closing operations"" catalog type';
			|it = 'Fills in the month-end closing settings with the ""Month-end closing operations"" catalog type';
			|pl = 'Fills in the month-end closing settings with the ""Month-end closing operations"" catalog type';
			|tr = 'Ay sonu kapama ayarlarını ""Ay sonu kapama işlemleri"" kataloğu tipiyle doldurur'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.MonthEndClosingOperations.FullName());
	ItemsToRead.Add(Metadata.Constants.MonthEndClosingSettings.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Constants.MonthEndClosingSettings.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Fills in parameters with the Reference Link type.Month Closure operationsreferences
//
Procedure ProcessDataSetConstantsShipmentWithoutPPP() Export
	
	ObjectMetadata = CreateValueManager().Metadata();
	Block = New DataLock;
	Block.Add("Constant.MonthEndClosingSettings");
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	MonthEndClosingOperations.Ref,
	|	MonthEndClosingOperations.PredefinedDataName
	|FROM
	|	Catalog.MonthEndClosingOperations AS MonthEndClosingOperations";
	
	SelectionOfMonthClosingOperations = Query.Execute().Select();
	
	MatchingOperations = New Map();
	
	While SelectionOfMonthClosingOperations.Next() Do
		MatchingOperations.Insert(
			SelectionOfMonthClosingOperations.PredefinedDataName,
			SelectionOfMonthClosingOperations.Ref);
	EndDo;
	
	BeginTransaction();
	
	Try
		
		Block.Lock();
		
		SetPrivilegedMode(True);
		SavedSettings = Constants.MonthEndClosingSettings.Get().Get(); // getting the contents of the value store
		SetPrivilegedMode(False);
		
		Updated_Settings = New Map;
		
		If Not SavedSettings = Undefined Then
			If TypeOf(SavedSettings) = Type("Map") Then
				For Each KeyAndValue In SavedSettings Do
					Operation = KeyAndValue.Key;
					If TypeOf(Operation) = Type("EnumRef.DeleteMonthEndClosingOperations") Then
						OperationName = XMLString(Operation);
						OperationCatalog = MatchingOperations.Get(OperationName);
						If OperationCatalog = Undefined Then
							ReportUnsuccessfulParameterProcessing(OperationName, ObjectMetadata);
						Else
							Updated_Settings.Insert(OperationCatalog, KeyAndValue.Value);
						EndIf;
					ElsIf TypeOf(Operation) = Type("CatalogRef.MonthEndClosingOperations") Then
						Updated_Settings.Insert(Operation, KeyAndValue.Value);
					EndIf;
				EndDo;
			EndIf;
			
			SetPrivilegedMode(True);
			Constants.MonthEndClosingSettings.Set(New ValueStorage(SavedSettings, New Deflation(9)));
			SetPrivilegedMode(False);
			
			RefreshReusableValues();
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Không thể xử lý đối tượng: %Object% do nguyên nhân: %Cause%';
							|ru = 'Не удалось обработать объект: %Object% по причине: %Cause%';
							|en = 'Cannot process object %Object%. Reason: %Cause%'; fa = 'Cannot process object %Object%. Reason: %Cause%';
							|it = 'Impossibile elaborare l''oggetto: %Object% motivo: %Cause%';
							|pl = 'Nie udało się przetworzyć obiekt: %Object% z powodu: %Cause%';
							|tr = '%Cause% nedeniyle nesne: %Object% işlenemedi'");
		MessageText = StrReplace(MessageText, "%Object%", ObjectMetadata.FullName());
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning,
			ObjectMetadata,
			ObjectMetadata.FullName(),
			MessageText);
		
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure ReportUnsuccessfulParameterProcessing(Parameter, ObjectMetadata)
	
	MessageText = NStr("vi = 'Không thể xử lý tùy chỉnh tham số kết chuyển cuối tháng: %Parameter% theo nguyên nhân: 
							|Không tìm thấy sự tương ứng trong danh mục ""Giao dịch kết chuyển cuối tháng""
							|với giá trị liệt kê ""(không sử dụng) Giao dịch kết chuyển cuối tháng""';
							|ru = 'Не удалось обработать настройки параметра закрытия месяца: %Parameter% по причине: 
							|Не найдено соответствие в справочнике ""Операции закрытие месяца""
							|значнеию перечисления ""(не используется) Операции закрытие месяца""';
							|en = 'Cannot process the settings of the %Parameter% month-end closing parameter. Reason: 
							|No match is found in the ""Month-end closing operations"" catalog
							| for the ""(not used) Month-end closing operations"" enumeration value'; fa = 'Cannot process the settings of the %Parameter% month-end closing parameter. Reason: 
							|No match is found in the ""Month-end closing operations"" catalog
							| for the ""(not used) Month-end closing operations"" enumeration value';
							|it = 'Cannot process the settings of the %Parameter% month-end closing parameter. Reason: 
							|No match is found in the ""Month-end closing operations"" catalog
							| for the ""(not used) Month-end closing operations"" enumeration value';
							|pl = 'Cannot process the settings of the %Parameter% month-end closing parameter. Reason: 
							|No match is found in the ""Month-end closing operations"" catalog
							| for the ""(not used) Month-end closing operations"" enumeration value';
							|tr = 'Ay sonu kapanışının parametre ayarları işlenemedi: %Parameter% nedeni: 
							|""Ay sonu kapama işlemleri"" kataloğunda
							|""(kullanılmıyor) Ay sonu kapama işlemleri"" numaralandırma değeri için eşleşme bulunamadı'");
	MessageText = StrReplace(MessageText, "%Object%", ObjectMetadata.FullName());
	MessageText = StrReplace(MessageText, "%Parameter%", Parameter);
	WriteLogEvent(InfobaseUpdate.EventLogEvent(),
		EventLogLevel.Warning,
		ObjectMetadata,
		ObjectMetadata.FullName(),
		MessageText);
		
EndProcedure

#EndRegion

#EndIf
