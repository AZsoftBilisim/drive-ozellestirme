#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm             - ClientApplicationForm - report form.
//   Cancel                - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	Parameters = ThisForm.Parameters;
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	
	If Parameters.Property("Details") 
		And TypeOf(Parameters.Details) = Type("Structure")
		And Parameters.Details.Property("CurrentPeriod") Then
	
		DetailsParameters = Parameters.Details;
		UsedSettings = FormSettingsComposer.FixedSettings;
		
		// To set the data parameters
		DataCompositionClientServer.SetParameter(UsedSettings, 
			"CurrentPeriod", DetailsParameters.CurrentPeriod);
		DataCompositionClientServer.SetParameter(UsedSettings, 
			"PreviousPeriod", DetailsParameters.PreviousPeriod);
		DataCompositionClientServer.SetParameter(UsedSettings, 
			"ClassificationParameterType", DetailsParameters.ClassificationParameterType);
		DataCompositionClientServer.SetParameter(UsedSettings, 
			"LineCur", NStr("vi = 'Hiện tại';
							|ru = 'Текущая';
							|en = 'Current'; fa = 'فعلی';
							|it = 'Corrente';
							|pl = 'Current';
							|tr = 'Mevcut'"));
		DataCompositionClientServer.SetParameter(UsedSettings, 
			"PreviousLine", NStr("vi = 'Trước';
								|ru = 'Предыдущая';
								|en = 'Previous'; fa = 'قبلی';
								|it = 'Precedente';
								|pl = 'Previous';
								|tr = 'Önceki'"));
			
		// To set the selection
		FilterDecryptions = UsedSettings.Filter; // DataCompositionFilter
		For Each Item In DetailsParameters.Filter Do
			FilterElement = FilterDecryptions.Items.Add(Type("DataCompositionFilterItem"));
			FilterElement.LeftValue  = New DataCompositionField(Item.Key);
			FilterElement.RightValue = Item.Value;
			FilterElement.Use  = True;
		EndDo;
		
		DetailsParameters.Insert("UsedSettings", UsedSettings);
	Else
		Cancel = True;
	EndIf;
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   ThisForm          - ClientApplicationForm - The report Form contains:
//     * Parameters - Structure - Contains:
//       ** Details - Structure - Contains:
//         *** Title - String -
//   NewDCSettings  - DataCompositionSettings - settings to be set.
//
Procedure OnLoadUserSettingsAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	Parameters = ThisForm.Parameters;

	If Not Parameters.Property("Details") 
		Or TypeOf(Parameters.Details) <> Type("Structure") Then
		Return;
	EndIf;
	
	// To install the headers
	DetailsParameters = Parameters.Details;
	Settings = Report.SettingsComposer.Settings; // DataCompositionSettings - 
	Settings.OutputParameters.SetParameterValue("Title", DetailsParameters.Title);
	Selection = Settings.Selection.Items;
	PreviousParameterValue = New DataCompositionField("PreviousClassificationParameterValue");
	CurParameterValue = New DataCompositionField("CurrentValueOfClassificationParameter");
	For Each Item In Selection Do
		If Item.Field = PreviousParameterValue
		 Or Item.Field = CurParameterValue Then
			Item.Title = DetailsParameters.ClassificationParameterType;
		EndIf;
	EndDo;
	
	// If there is a Decryption, the Selection and Data Parameters will get into the Settings from the Fixed Settings
	For Each Parameter In Settings.DataParameters.Items Do
		Parameter.Value = Undefined;
		Parameter.Use = False;
	EndDo;
	Settings.Filter.Items.Clear();
	
EndProcedure

#EndRegion

#EndIf