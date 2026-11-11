 #Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Products = Parameters.Products;
	
#If MobileStandaloneServer Then
	Items.AddNewOne.Visible = False;
#EndIf
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateForm();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddNewOne(Command)
	
	If UsedFormServer = UsedServer.Main Then
		FillingValues = New Structure;
		FillingValues.Insert("Products", Products);
		
		FormParameters = New Structure;
		FormParameters.Insert("FillingValues", FillingValues);
		
		CallbackDescription = New CallbackDescription("UpdateForm", ThisObject);
		
		OpenForm("InformationRegister.ItemsBarcodes.RecordForm",
			FormParameters,
			ThisObject,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.Independent);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateFormOnServer();

EndProcedure

&AtServer
Procedure UpdateFormOnServer()
	
	Barcodes.Clear();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ItemsBarcodes.Barcode			AS Barcode,
	|	ItemsBarcodes.Characteristic	AS Characteristic,
	|	ItemsBarcodes.Series				AS Series,
	|	ItemsBarcodes.Package			AS Package
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|WHERE
	|	ItemsBarcodes.Products = &Products";
	
	Query.SetParameter("Products", Products);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;

	//Barcodes.
	Barcodes.Load(QueryResult.Unload());
	
EndProcedure

#EndRegion
