
#Region Public

// The event handler
// for the system's Beginningbotwork is called to perform the actions required for the system's Openingforminternatingbotwork subsystem.
//
Procedure OnStart() Export
	
	ArrayOfForms = StandardSubsystemsClient.ClientParametersOnStart().FormsOpenedOnApplicationStart;
	
	For Each CurrentForm In ArrayOfForms Do
		
		If CurrentForm.OpenByDefault Then
			
			OpenCurForm(CurrentForm);
			
		Else
			
			If StrFind(Upper(LaunchParameter), Upper(CurrentForm.LaunchParameter)) = 0 Then
				Continue;
			EndIf;
			
			OpenCurForm(CurrentForm);
			
		EndIf;
		
	EndDo;
	
	FormName = StandardSubsystemsClient.ClientParametersOnStart().ServiceSubsystems_ObjectsOfTMCAERP_InitialProgramSetupForm;
	
	If Not IsBlankString(FormName) Then
		
		CurrentForm = OpenFormsOnApplicationStartClientServerOverridable.DescriptionOfFormSettings();
		CurrentForm.Insert("NameOfFormToRun", FormName);
		CurrentForm.Insert("OpenModally", True);
		
		OpenCurForm(CurrentForm);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Opens the required workplace form.
//
// Parameters:
//	CurFormParameters - Structure - parameters for opening the workplace form (cashier, sales assistant, etc.).
//
Procedure OpenCurForm(CurFormParameters)
	
	If CurFormParameters.RequiredSettings And Not CurFormParameters.SettingsAreSet Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi thử mở biểu mẫu ""%1"" đã xảy ra lỗi - chưa đặt tùy chỉnh biểu mẫu. Hãy liên hệ với người quản trị.';
				|ru = 'При попытке открытия формы ""%1"" произошла ошибка - не заданы настройки формы. Обратитесь к администратору.';
				|en = 'An error occurred when trying to open the ""%1"" form - form settings are not specified. Please contact the administrator.'; fa = 'An error occurred when trying to open the ""%1"" form - form settings are not specified. Please contact the administrator.';
				|it = 'Durante il tentativo di aprire il modulo ""%1"" si è verificato un errore - non sono indicate le impostazioni del modulo. Rivolgersi all''amministratore.';
				|pl = 'Podczas próby otwarcia formularza ""%1"" zaistniał błąd - nie są określone ustawienia formularza. Zwróć się do administratora.';
				|tr = '""%1"" formu açılmaya çalışılırken hata oluştu - hiçbir form ayarı belirtilmedi. Yöneticiyle iletişime geç.'"),
			CurFormParameters.NameOfFormToRun);
		
		Raise MessageText;
		
	EndIf;
	
	If Upper(CurFormParameters.LaunchParameter) = Upper("WarehouseMobileWorkplace") Then
		
		If Not CurFormParameters.Parameters.Property("ScreenResolution") Then
			
			NameOfFormToRun = "DataProcessor.WorkplaceOfWarehouseWorker.Form.WarehouseWorkerMWP_320x320";
			
		Else
			
			If CurFormParameters.Parameters.ScreenResolution = PredefinedValue("Enum.ScreenResolutions.Resolution320x320") Then
				
				NameOfFormToRun = "DataProcessor.WorkplaceOfWarehouseWorker.Form.WarehouseWorkerMWP_320x320";
				
			ElsIf CurFormParameters.Parameters.ScreenResolution = PredefinedValue("Enum.ScreenResolutions.Resolution240x320") Then
				
				NameOfFormToRun = "DataProcessor.WorkplaceOfWarehouseWorker.Form.WarehouseWorkerMWP_240x320";
				
			ElsIf CurFormParameters.Parameters.ScreenResolution = PredefinedValue("Enum.ScreenResolutions.Resolution480x640") Then
				
				NameOfFormToRun = "DataProcessor.WorkplaceOfWarehouseWorker.Form.WarehouseWorkerMWP480x640";
				
			EndIf;
			
		EndIf;
		
	ElsIf Upper(CurFormParameters.LaunchParameter) = Upper("PerformanceDashboard") Then
		
		#If MobileClient Then
			NameOfFormToRun = "Catalog.PerformanceDashboards.ListForm";
		#Else
			NameOfFormToRun = CurFormParameters.NameOfFormToRun;
		#EndIf
		
	Else
		
		NameOfFormToRun = CurFormParameters.NameOfFormToRun;
		
	EndIf;
	
	FormOpenParameters = New Structure;
	For Each KeyAndValue In CurFormParameters.Parameters Do
		FormOpenParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	If CurFormParameters.OpenModally Then
		OpenForm(NameOfFormToRun, FormOpenParameters,,,,, Undefined, FormWindowOpeningMode.LockWholeInterface);
	Else
		
		KeyOperationName = StrTemplate(
		"OpenFormsOnApplicationStartClient.%1", NameOfFormToRun);
		PerformanceMonitorClient.TimeMeasurement(KeyOperationName);
		
		OpenForm(NameOfFormToRun, FormOpenParameters);
	EndIf;
	
EndProcedure

#EndRegion
