
#Region Public

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.ApplicationsSize);
	Types.Add(Metadata.InformationRegisters.SizeOfApplicationMetadataObjects);
	
EndProcedure

#EndRegion

#Region Internal

// Application size calculation is supported.
// 
// Returns:
//  Boolean
Function ApplicationSizeCalculationIsSupported() Export
	
	Info = New SystemInfo;
	MinVersion = MinPlatformVersion1();
	 
	If CommonClientServer.CompareVersions(
		Info.AppVersion, MinVersion) < 0 Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

Procedure CheckSupportForAppSizeCalculation() Export
	
	If Not ApplicationSizeCalculationIsSupported() Then
		Raise(NStr("vi = 'Không hỗ trợ chức năng tính toán dung lượng ứng dụng';
					|ru = 'Функциональность расчета размера приложений не поддерживается';
					|en = 'Application size calculation functionality is not supported'; fa = 'Application size calculation functionality is not supported';
					|it = 'Funzionalità di calcolo dimensione applicazione non supportata';
					|pl = 'Funkcje obliczenia rozmiaru aplikacji nie są obsługiwane';
					|tr = 'Uygulama boyut hesaplama işlevi desteklenmiyor'"));
	EndIf;
	
EndProcedure

// @skip-warning EmptyMethod - a feature of the implementation.
Procedure ScheduleApplicationSizeCalculation(DataArea = Undefined) Export

EndProcedure

Procedure CalculateApplicationSize() Export
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện giao dịch';
					|ru = 'Недостаточно прав для выполнения операции';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji';
					|tr = 'İşlem için gerekli yetkiler yok'"));
	EndIf;
	
	CheckSupportForAppSizeCalculation();
	
	DataModel = SaaSOperationsCached.GetAreaDataModel();
	MetadataSize = ApplicationMetadataSize();
	CalculationParameters = Constants.ApplicationSizeCalculationSettings.Get().Get();
	
	ApplicationSize = 0;
	MinimumStepChanges = CalculationSettingValue("MinimumStepChanges", 0, CalculationParameters);
	
	Parameters = New Structure();
	Parameters.Insert("ListOfObjects", New Array(1));
	
	For Each ModelItem In DataModel Do
		
		MetadataObject = ModelItem.Key;
		Parameters.ListOfObjects[0] = MetadataObject;
		
		Size = Common.CalculateInSafeMode(
			"GetDatabaseDataSize(, Parameters.ListOfObjects)",
			Parameters);
		RecordedSize = RecordApplicationMetadataSize(
			MetadataSize, MetadataObject, Size, MinimumStepChanges);
		
		MetadataSize.Delete(MetadataObject);
		ApplicationSize = ApplicationSize + RecordedSize; 
		
	EndDo;
	
	For Each MetadataElement In MetadataSize Do
		RecordApplicationMetadataSize(MetadataSize, MetadataElement.Key);
	EndDo;
	
	RecordApplicationSize(ApplicationSize);
		
EndProcedure

// Returns part of the full name of the metadata object
// 
// Parameters:
// 	MetadataObject - String - full name of the metadata object
// 	PartNumber - Number - the part number of the metadata object name (0 is the type of metadata, 1 is the name)
// Returns:
// 	String - Part of the full name of the metadata object
Function PartOfMetadataObjectSFullName(MetadataObject, PartNumber) Export
	
	FullNameParts1 = StrSplit(MetadataObject, ".", False);
	If FullNameParts1.Count() < PartNumber Then
		Return "";
	EndIf;
	
	Return FullNameParts1[PartNumber - 1];
	
EndFunction

// Returns the current date of calculating the size of the application
// 
// Returns:
// 	Date - Current date of application size calculation
Function RelevanceOfApplicationSizeCalculation() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ApplicationsSize.DateOfCalculation AS DateOfCalculation
	|FROM
	|	InformationRegister.ApplicationsSize AS ApplicationsSize";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Date(1, 1, 1);
	EndIf;
	
	SamplingResult = Result.Select();
	SamplingResult.Next();
	
	Return SamplingResult.DateOfCalculation;
	
EndFunction

// Checks if there is a task to calculate the size of the application
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	DataArea - Number - data area number
// Returns:
// 	Boolean - True if there are scheduled tasks calculating the size of the application
Function ThereIsScheduledJobCalculatingSizeOfApplication(DataArea = Undefined) Export

EndFunction

// Gets the value of the application size calculation setting
// 
// Parameters:
// 	SettingName - String - setting name
// 	DefaultValue - String, Number, Date - the value returned if the setting is not found 
// 	Settings - FixedStructure - application size calculation settings 
// Returns:
// 	String, Number, Date - setting value
Function CalculationSettingValue(SettingName, DefaultValue = Undefined, Settings = Undefined) Export
	
	If Settings = Undefined Then
		
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Settings = Constants.ApplicationSizeCalculationSettings.Get().Get();
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
		
	EndIf;
	
	If TypeOf(Settings) <> Type("FixedStructure")
		Or Not Settings.Property(SettingName) Then
		Return DefaultValue;
	EndIf;
	
	Return Settings[SettingName];
	
EndFunction

#EndRegion

#Region Private

Function RecordApplicationMetadataSize(MetadataSize,
										   MetadataObject,
										   Size = Undefined,
										   MinimumStepChanges = Undefined)
	
	PerformRecording_ = False;
	RecordedSize = 0;
	PreviousSize = MetadataSize.Get(MetadataObject);
	
	If PreviousSize = Undefined Then
		PerformRecording_ = Size <> Undefined And Size > 0;
	ElsIf Size = Undefined Then
		 Size = 0;
		 PerformRecording_ = True;
	Else
		
		SizeDifference = Size - PreviousSize;
		If SizeDifference < 0 Then
			SizeDifference = -1 * SizeDifference;
		EndIf;
		
		If MinimumStepChanges = Undefined Then
			MinimumStepChanges = 0;
		EndIf;
		
		If SizeDifference > 0 And SizeDifference >= MinimumStepChanges Then
			PerformRecording_ = True;
		EndIf;
		
		RecordedSize = PreviousSize;
		
	EndIf;
	
	If PerformRecording_ Then
		
		Record = InformationRegisters.SizeOfApplicationMetadataObjects.CreateRecordManager();
		Record.Period = CurrentSessionDate();
		Record.MetadataObject = MetadataObject;
		Record.Size = Size;
		Record.Write();
		
		RecordedSize = Size;
		
	EndIf;
	
	Return RecordedSize;
	
EndFunction

Procedure RecordApplicationSize(Size, ErrorText = Undefined)
	
	Record = InformationRegisters.ApplicationsSize.CreateRecordManager();
	Record.Size = Size;
	Record.DateOfCalculation = CurrentSessionDate();
	
	If ErrorText <> Undefined Then
		Record.ProcessingError = True;
		Record.ErrorText = ErrorText;
	Else
		Record.NotifyChanged = True;
	EndIf;
	 
	 Record.Write();
	
EndProcedure

Function ApplicationMetadataSize()
	
	MetadataSize = New Map();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SizeOfMetadataObjects.MetadataObject,
	|	SizeOfMetadataObjects.Size
	|FROM
	|	InformationRegister.SizeOfApplicationMetadataObjects.SliceLast AS SizeOfMetadataObjects";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return MetadataSize;
	EndIf;
	
	SamplingResult = Result.Select();
	While SamplingResult.Next() Do
		MetadataSize.Insert(SamplingResult.MetadataObject, SamplingResult.Size);
	EndDo;
	
	Return MetadataSize;
	
EndFunction

Function MinPlatformVersion1()
	
	Return "8.3.15.1000";
	
EndFunction

#EndRegion
