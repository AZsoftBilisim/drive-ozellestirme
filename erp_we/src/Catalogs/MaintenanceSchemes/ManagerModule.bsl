#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Procedure for checking whether the table parts of planning rules are filled in
//
// Parameters:
// 		Object - CatalogObject.MaintenanceSchemes, CatalogObject.MaintenanceSchemeOptions - Directory object whose table parts need to be checked
// 		NotCheckedAttributeArray - Array - Array of names of Bank details to be removed from the checked ones
// 		Cancel - Boolean - error flag.
//
Procedure CheckingCompletionOfPlanningRules(Object, NotCheckedAttributeArray, Cancel = False) Export
	
	NotCheckedAttributeArray.Add("RMCycle.TimeInterval");
	NotCheckedAttributeArray.Add("RMCycle.PlanningTimeInterval");
	NotCheckedAttributeArray.Add("RMCycle.TimeUnit");
	NotCheckedAttributeArray.Add("RMCycle.RunningTimeInterval");
	NotCheckedAttributeArray.Add("RMCycle.PlanningTimeInterval_");
	NotCheckedAttributeArray.Add("RMCycle.RunningTimeValue");
	NotCheckedAttributeArray.Add("OtherRMActivities.TimeInterval");
	NotCheckedAttributeArray.Add("OtherRMActivities.PlanningTimeInterval");
	NotCheckedAttributeArray.Add("OtherRMActivities.TimeUnit");
	NotCheckedAttributeArray.Add("OtherRMActivities.RunningTimeInterval");
	NotCheckedAttributeArray.Add("OtherRMActivities.PlanningTimeInterval_");
	NotCheckedAttributeArray.Add("OtherRMActivities.RunningTimeValue");
	
	ComplianceWithTypesOfRepairs = New Map;
	
	For Each String In Object.RMCycle Do
		
		ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ''''Chu kỳ sửa chữa''''';
							|ru = 'в строке %LineNumber% списка ""Ремонтный цикл""';
							|en = 'in line %LineNumber% of the ""R&M cycle"" list'; fa = 'in line %LineNumber% of the ""R&M cycle"" list';
							|it = 'nella riga %LineNumber% dell''elenco ""Ciclo di manutenzione""';
							|pl = 'w wierszu %LineNumber% listy ""Cykl remontowy""';
							|tr = '""Onarım döngüsü"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", String.LineNumber);
		
		LineNumber = String.LineNumber;
		
		If ComplianceWithTypesOfRepairs.Get(String.RMType) <> Undefined Then
			// The type of repair is already present in the tabular part in another line
			
			ErrorText = NStr("vi = 'Dạng sửa chữa ""%RMType%"" %ErrorAddress% đã có trong dòng %PreviousLineNumber%';
							|ru = 'Вид ремонта ""%RMType%"" %ErrorAddress% уже присутствует в строке %PreviousLineNumber%';
							|en = 'Line %PreviousLineNumber% already contains the ""%RMType%"" R&M work %ErrorAddress%'; fa = 'Line %PreviousLineNumber% already contains the ""%RMType%"" R&M work %ErrorAddress%';
							|it = 'Il tipo di manutenzione ""%RMType%"" %ErrorAddress% è già presente nella riga %PreviousLineNumber%';
							|pl = 'Rodzaj remontu ""%RMType%"" %ErrorAddress% już istnieje w wierszu %PreviousLineNumber%';
							|tr = 'Onarım türü ""%RMType%"" %ErrorAddress%%PreviousLineNumber% dizesinde mevcut'");
			ErrorText = StrReplace(ErrorText, "%ErrorAddress%", ErrorAddress);
			ErrorText = StrReplace(ErrorText, "%RMType%", String.RMType);
			ErrorText = StrReplace(ErrorText, "%PreviousLineNumber%", Format(ComplianceWithTypesOfRepairs.Get(String.RMType), "NG=0"));
			
			CommonClientServer.MessageToUser(
				ErrorText,
				Object,
				CommonClientServer.PathToTabularSection("RMCycle", String.LineNumber, "RMType"),,
				Cancel);
		Else
			ComplianceWithTypesOfRepairs.Insert(String.RMType, LineNumber);
		EndIf;
		
		If Object.RMIntervalByActivityRecords Then
			
			If Not ValueIsFilled(String.RunningTimeInterval) Then
				CommonClientServer.MessageToUser(
					StrReplace(NStr("vi = 'Cột ""Khoảng cách sửa chữa"" không được điền %ErrorAddress%';
									|ru = 'Не заполнена колонка ""Межремонтный интервал"" %ErrorAddress%';
									|en = 'The ""R&M interval"" column is required %ErrorAddress%'; fa = 'The ""R&M interval"" column is required %ErrorAddress%';
									|it = 'Non è compilata la colonna ""Intervallo tra manutenzioni"" %ErrorAddress%';
									|pl = 'Nie wypełniono kolumny ""Interwał miedzy remontami"" %ErrorAddress%';
									|tr = '""Revizyon aralığı"" sütunu doldurulmamış %ErrorAddress%'"), "%ErrorAddress%", ErrorAddress),
					Object,
					CommonClientServer.PathToTabularSection("RMCycle", String.LineNumber, "RunningTimeInterval"),
					,
					Cancel);
			EndIf;
			
			If Not ValueIsFilled(String.RunningTimeValue) Then
				CommonClientServer.MessageToUser(
					StrReplace(NStr("vi = 'Cột ""Đơn vị tính"" không được điền %ErrorAddress%';
									|ru = 'Не заполнена колонка ""Единица измерения"" %ErrorAddress%';
									|en = 'The ""Unit of measure"" column is required %ErrorAddress%'; fa = 'The ""Unit of measure"" column is required %ErrorAddress%';
									|it = 'La colonna ""Unità di misura"" non è stata compilata %ErrorAddress%';
									|pl = 'Nie wypełniono kolumny ""Jednostka miary"" %ErrorAddress%';
									|tr = '""Ölçü Birimi"" sütunu doldurulmamış %ErrorAddress%'"), "%ErrorAddress%", ErrorAddress),
					Object,
					CommonClientServer.PathToTabularSection("RMCycle", String.LineNumber, "RunningTimeValue"),
					,
					Cancel);
			EndIf;
			
		Else
			
			If Not ValueIsFilled(String.TimeInterval) Then
				CommonClientServer.MessageToUser(
					StrReplace(NStr("vi = 'Cột ""Khoảng cách sửa chữa"" không được điền %ErrorAddress%';
									|ru = 'Не заполнена колонка ""Межремонтный интервал"" %ErrorAddress%';
									|en = 'The ""R&M interval"" column is required %ErrorAddress%'; fa = 'The ""R&M interval"" column is required %ErrorAddress%';
									|it = 'Non è compilata la colonna ""Intervallo tra manutenzioni"" %ErrorAddress%';
									|pl = 'Nie wypełniono kolumny ""Interwał miedzy remontami"" %ErrorAddress%';
									|tr = '""Revizyon aralığı"" sütunu doldurulmamış %ErrorAddress%'"), "%ErrorAddress%", ErrorAddress),
					Object,
					CommonClientServer.PathToTabularSection("RMCycle", String.LineNumber, "TimeInterval"),
					,
					Cancel);
			EndIf;
			
			If Not ValueIsFilled(String.TimeUnit) Then
				CommonClientServer.MessageToUser(
					StrReplace(NStr("vi = 'Cột ""Đơn vị tính"" không được điền %ErrorAddress%';
									|ru = 'Не заполнена колонка ""Единица измерения"" %ErrorAddress%';
									|en = 'The ""Unit of measure"" column is required %ErrorAddress%'; fa = 'The ""Unit of measure"" column is required %ErrorAddress%';
									|it = 'La colonna ""Unità di misura"" non è stata compilata %ErrorAddress%';
									|pl = 'Nie wypełniono kolumny ""Jednostka miary"" %ErrorAddress%';
									|tr = '""Ölçü Birimi"" sütunu doldurulmamış %ErrorAddress%'"), "%ErrorAddress%", ErrorAddress),
					Object,
					CommonClientServer.PathToTabularSection("RMCycle", String.LineNumber, "TimeUnit"),
					,
					Cancel);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ComplianceWithTypesOfRepairs.Clear();
	
	For Each String In Object.OtherRMActivities Do
		
		ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Sửa chữa khác""';
							|ru = 'в строке %LineNumber% списка ""Прочие ремонты""';
							|en = 'in line %LineNumber% of the ""Other R&M"" list'; fa = 'in line %LineNumber% of the ""Other R&M"" list';
							|it = 'nella riga %LineNumber% dell''elenco ""Altra manutenzione""';
							|pl = 'w wierszu %LineNumber% listy ""Inne remonty""';
							|tr = '""Diğer onarımlar"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", String.LineNumber);
		
		If ComplianceWithTypesOfRepairs.Get(String.RMType) <> Undefined Then
			// The type of repair is already present in the tabular part in another line
			
			ErrorText = NStr("vi = 'Dạng sửa chữa ""%RMType%"" %ErrorAddress% đã có trong dòng %PreviousLineNumber%';
							|ru = 'Вид ремонта ""%RMType%"" %ErrorAddress% уже присутствует в строке %PreviousLineNumber%';
							|en = 'Line %PreviousLineNumber% already contains the ""%RMType%"" R&M work %ErrorAddress%'; fa = 'Line %PreviousLineNumber% already contains the ""%RMType%"" R&M work %ErrorAddress%';
							|it = 'Il tipo di manutenzione ""%RMType%"" %ErrorAddress% è già presente nella riga %PreviousLineNumber%';
							|pl = 'Rodzaj remontu ""%RMType%"" %ErrorAddress% już istnieje w wierszu %PreviousLineNumber%';
							|tr = 'Onarım türü ""%RMType%"" %ErrorAddress%%PreviousLineNumber% dizesinde mevcut'");
			ErrorText = StrReplace(ErrorText, "%ErrorAddress%", ErrorAddress);
			ErrorText = StrReplace(ErrorText, "%RMType%", String.RMType);
			ErrorText = StrReplace(ErrorText, "%PreviousLineNumber%", Format(ComplianceWithTypesOfRepairs.Get(String.RMType), "NG=0"));
			
			CommonClientServer.MessageToUser(
				ErrorText,
				Object,
				CommonClientServer.PathToTabularSection("RMCycle", String.LineNumber, "RMType"),,
				Cancel);
		Else
			ComplianceWithTypesOfRepairs.Insert(String.RMType, LineNumber);
		EndIf;
		
		If String.ByAssetActivity Then
			
			If Not ValueIsFilled(String.RunningTimeInterval) Then
				CommonClientServer.MessageToUser(
					StrReplace(NStr("vi = 'Cột ""Khoảng cách sửa chữa"" không được điền %ErrorAddress%';
									|ru = 'Не заполнена колонка ""Межремонтный интервал"" %ErrorAddress%';
									|en = 'The ""R&M interval"" column is required %ErrorAddress%'; fa = 'The ""R&M interval"" column is required %ErrorAddress%';
									|it = 'Non è compilata la colonna ""Intervallo tra manutenzioni"" %ErrorAddress%';
									|pl = 'Nie wypełniono kolumny ""Interwał miedzy remontami"" %ErrorAddress%';
									|tr = '""Revizyon aralığı"" sütunu doldurulmamış %ErrorAddress%'"), "%ErrorAddress%", ErrorAddress),
					Object,
					CommonClientServer.PathToTabularSection("OtherRMActivities", String.LineNumber, "RunningTimeInterval"),
					,
					Cancel);
			EndIf;
			
			If Not ValueIsFilled(String.RunningTimeValue) Then
				CommonClientServer.MessageToUser(
					StrReplace(NStr("vi = 'Cột ""Đơn vị tính"" không được điền %ErrorAddress%';
									|ru = 'Не заполнена колонка ""Единица измерения"" %ErrorAddress%';
									|en = 'The ""Unit of measure"" column is required %ErrorAddress%'; fa = 'The ""Unit of measure"" column is required %ErrorAddress%';
									|it = 'La colonna ""Unità di misura"" non è stata compilata %ErrorAddress%';
									|pl = 'Nie wypełniono kolumny ""Jednostka miary"" %ErrorAddress%';
									|tr = '""Ölçü Birimi"" sütunu doldurulmamış %ErrorAddress%'"), "%ErrorAddress%", ErrorAddress),
					Object,
					CommonClientServer.PathToTabularSection("OtherRMActivities", String.LineNumber, "RunningTimeValue"),
					,
					Cancel);
			EndIf;
			
		Else
			
			If Not ValueIsFilled(String.TimeInterval) Then
				CommonClientServer.MessageToUser(
					StrReplace(NStr("vi = 'Cột ""Khoảng cách sửa chữa"" không được điền %ErrorAddress%';
									|ru = 'Не заполнена колонка ""Межремонтный интервал"" %ErrorAddress%';
									|en = 'The ""R&M interval"" column is required %ErrorAddress%'; fa = 'The ""R&M interval"" column is required %ErrorAddress%';
									|it = 'Non è compilata la colonna ""Intervallo tra manutenzioni"" %ErrorAddress%';
									|pl = 'Nie wypełniono kolumny ""Interwał miedzy remontami"" %ErrorAddress%';
									|tr = '""Revizyon aralığı"" sütunu doldurulmamış %ErrorAddress%'"), "%ErrorAddress%", ErrorAddress),
					Object,
					CommonClientServer.PathToTabularSection("OtherRMActivities", String.LineNumber, "TimeInterval"),
					,
					Cancel);
			EndIf;
			
			If Not ValueIsFilled(String.TimeUnit) Then
				CommonClientServer.MessageToUser(
					StrReplace(NStr("vi = 'Cột ""Đơn vị tính"" không được điền %ErrorAddress%';
									|ru = 'Не заполнена колонка ""Единица измерения"" %ErrorAddress%';
									|en = 'The ""Unit of measure"" column is required %ErrorAddress%'; fa = 'The ""Unit of measure"" column is required %ErrorAddress%';
									|it = 'La colonna ""Unità di misura"" non è stata compilata %ErrorAddress%';
									|pl = 'Nie wypełniono kolumny ""Jednostka miary"" %ErrorAddress%';
									|tr = '""Ölçü Birimi"" sütunu doldurulmamış %ErrorAddress%'"), "%ErrorAddress%", ErrorAddress),
					Object,
					CommonClientServer.PathToTabularSection("OtherRMActivities", String.LineNumber, "TimeUnit"),
					,
					Cancel);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns sets of properties for the class of operational objects
//
// Parameters:
// 		Class - CatalogRef.MaintenanceSchemes - Link to the class.
//
// Returns:
// 		Structure - Structure of property sets.
//
Function GetPropertySets(Class) Export
	
	StructureOfSets = New Structure(
		"PassportData",
		Undefined);
	
	Query = New Query(
		"SELECT
		|	Classes.PropertiesSet AS PassportData
		|FROM
		|	Catalog.MaintenanceSchemes AS Classes
		|WHERE
		|	Classes.Ref = &Ref");
	Query.SetParameter("Ref", Class);
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return StructureOfSets;
	EndIf;
	
	Selection = Result.Select();
	If Selection.Next() Then
		FillPropertyValues(StructureOfSets, Selection);
	EndIf;
	
	Return StructureOfSets;
	
EndFunction

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf
