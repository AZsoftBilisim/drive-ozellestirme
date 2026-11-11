#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Owner = Undefined;
	
	If Parameters.Property("Filter")
		And Parameters.Filter.Property("Owner") Then
		
		Owner = Parameters.Filter.Owner;
		
	EndIf;
	
	If Owner <> Catalogs.PackagingGroups.BasicUnitsOfMeasure Then
		ExceptionText = NStr("vi = 'Biểu mẫu được dự định chỉ hiển thị một danh sách các đơn vị đóng gói.';
							|ru = 'Форма предназначена для отображения только списка единиц упаковок.';
							|en = 'The form is supposed to contain only packaging units.'; fa = 'The form is supposed to contain only packaging units.';
							|it = 'Il modulo ha lo scopo di visualizzare solo l''elenco di unità di imballaggi.';
							|pl = 'Formularz jest przeznaczony do odzwierciedlania tylko listy jednostek opakowań.';
							|tr = 'Form, yalnızca paketleme ünitesi birimlerinin listesini görüntülemek için tasarlanmıştır.'");
		
		Raise ExceptionText;
	EndIf;
	
	Items.SelectingFromClassifier.Visible = AccessRight("Insert", Metadata.Catalogs.PackagesAndUnitsOfMeasure);
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(ThisObject);
	// End StandardSubsystems.Core
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectingFromClassifier(Command)
	
	
	OpenBuiltInSelection(Undefined, Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenBuiltInSelection(Result, AdditionalParameters) Export
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.UnitOfMeasureClassifier",
		,
		ThisObject,
		,
		,
		,
		New CallbackDescription("SelectingFromClassifierCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure SelectingFromClassifierCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure")
		And Result.Property("NumberOfNewItems_") Then
		
		ProductsClient.NotifyAboutChangesInUnitSelectionList(
			Result.NumberOfNewItems_,
			Result.NewItems);
		
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion
