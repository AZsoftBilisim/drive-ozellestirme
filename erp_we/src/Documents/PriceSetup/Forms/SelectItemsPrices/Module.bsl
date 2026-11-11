
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ProductPricingDocumentFormUUID = Parameters.UUID;
	AddressDataForPrintingInTheTemporaryStorage = Parameters.AddressDataForPrintingInTheTemporaryStorage;
	
	DataForPrint = Undefined;
	If ValueIsFilled(AddressDataForPrintingInTheTemporaryStorage) Then
		DataForPrint = GetFromTempStorage(AddressDataForPrintingInTheTemporaryStorage);
	EndIf;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	TypesOfPrices.Ref            AS Ref,
	|	TypesOfPrices.Description      AS Description,
	|	TypesOfPrices.PricingMethod AS PricingMethod,
	|	CASE
	|		WHEN
	|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.Manually)
	|		THEN
	|			0
	|		WHEN
	|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.FillInByInfobaseData)
	|		THEN
	|			1
	|		WHEN
	|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes)
	|		THEN
	|			2
	|	END AS PictureIndex
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	TypesOfPrices.Ref IN(&ArrayOfPriceTypes)
	|ORDER BY
	|	TypesOfPrices.AddlOrderingAttribute
	|";
	
	If DataForPrint = Undefined Then
		Query.SetParameter("ArrayOfPriceTypes", TypesOfDocumentPrices(Parameters.DocumentsArray));
	Else
		Query.SetParameter("ArrayOfPriceTypes", DataForPrint.TypesOfPrices);
	EndIf;
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		NewLinePriceView = SettingsTree.GetItems().Add();
		NewLinePriceView.Description  = Selection.Description;
		NewLinePriceView.Parameter = Selection.Ref;
		NewLinePriceView.PictureIndex = Selection.PictureIndex;
		NewLinePriceView.Print = 1;
		
		NewRowColumn = NewLinePriceView.GetItems().Add();
		NewRowColumn.Description = NStr("vi = 'Đơn giá cũ';
										|ru = 'Старая цена';
										|en = 'Old price'; fa = 'قیمت قدیم';
										|it = 'Prezzo vecchio';
										|pl = 'Stara cena';
										|tr = 'Eski fiyat'");
		NewRowColumn.Parameter = "OldPrice";
		NewRowColumn.PictureIndex = -1;
		NewRowColumn.Print = 1;
		
		NewRowColumn = NewLinePriceView.GetItems().Add();
		NewRowColumn.Description = NStr("vi = 'Số tiền thay đổi';
										|ru = 'Сумма изменения';
										|en = 'Change amount'; fa = 'مبلغ باقی‌مانده برگشتی';
										|it = 'Importo di variazione';
										|pl = 'Wartość zmiany';
										|tr = 'Değişiklik tutarı'");
		NewRowColumn.Parameter = "AmountOfChange";
		NewRowColumn.PictureIndex = -1;
		NewRowColumn.Print = 1;
		
		NewRowColumn = NewLinePriceView.GetItems().Add();
		NewRowColumn.Description = NStr("vi = 'Phần trăm thay đổi';
										|ru = 'Процент изменения';
										|en = 'Change percentage'; fa = 'درصد تغییر';
										|it = 'Percentuale di variazione';
										|pl = 'Procent zmiany';
										|tr = 'Değişiklik yüzdesi'");
		NewRowColumn.Parameter = "ChangePercentage";
		NewRowColumn.PictureIndex = -1;
		NewRowColumn.Print = 1;
		
	EndDo;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettingsTree

&AtClient
Procedure SettingsTreePrintOnChange(Item)
	
	CurrentRow = SettingsTree.FindByID(Items.SettingsTree.CurrentRow);
	If TypeOf(CurrentRow.Parameter) = Type("CatalogRef.TypesOfPrices") Then
		
		If CurrentRow.Print = 2 Then
			CurrentRow.Print = 0;
		EndIf;
		
	Else
		
		If CurrentRow.Print = 2 Then
			CurrentRow.Print = 0;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	NumberOfSelectdPriceTypes = 0;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("SettingsTree", PutItInTemporaryStorageOnServer());
	PrintParameters.Insert("SettingsTreeForClient", PutInTemporaryStorageOnServerForClient(NumberOfSelectdPriceTypes));
	PrintParameters.Insert("PrintOnlyChangedPrices", OnlyChangedPrices);
	PrintParameters.Insert("DisplayHeader", True);
	PrintParameters.Insert("NumberOfSelectdPriceTypes", NumberOfSelectdPriceTypes);
	PrintParameters.Insert("AddressDataForPrintingInTheTemporaryStorage", AddressDataForPrintingInTheTemporaryStorage);
	
	Close(PrintParameters);
	
EndProcedure

&AtClient
Procedure PriceTypesSelectAll(Command)
	
	For Each PriceKind In SettingsTree.GetItems() Do
		PriceKind.Print = 1;
	EndDo;
	
EndProcedure

&AtClient
Procedure PriceTypesExcludeAll(Command)
	
	For Each PriceKind In SettingsTree.GetItems() Do
		PriceKind.Print = 0;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Function TypesOfDocumentPrices(DocumentsArray)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	PriceSetupTypesOfPrices.PriceKind AS PriceKind
	|FROM
	|	Document.PriceSetup.TypesOfPrices AS PriceSetupTypesOfPrices
	|WHERE
	|	PriceSetupTypesOfPrices.Ref IN(&DocumentsArray)";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query.Execute().Unload().UnloadColumn("PriceKind");
	
EndFunction

&AtServer
Function PutInTemporaryStorageOnServerForClient(NumberOfSelectdPriceTypes)
	
	Array = New Array;
	
	Tree = FormDataToValue(SettingsTree, Type("ValueTree"));
	For Each String In Tree.Rows Do
		
		NewRow = New Structure("Description, Print, Parameter, Rows", , , , New Array);
		FillPropertyValues(NewRow, String, , "Rows");
		
		NumberOfSelectdPriceTypes = NumberOfSelectdPriceTypes + NewRow.Print;
		
		For Each Line2Level In String.Rows Do
			NewLine2Level = New Structure("Description, Print, Parameter");
			FillPropertyValues(NewLine2Level, Line2Level);
			NewRow.Rows.Add(NewLine2Level);
		EndDo;
		
		Array.Add(NewRow);
		
	EndDo;
	
	Return PutToTempStorage(New Structure("Rows", Array), ProductPricingDocumentFormUUID);
	
EndFunction

&AtServer
Function PutItInTemporaryStorageOnServer()
	
	Tree = FormDataToValue(SettingsTree, Type("ValueTree"));
	Return PutToTempStorage(Tree, ProductPricingDocumentFormUUID);
	
EndFunction

#EndRegion

#EndRegion
