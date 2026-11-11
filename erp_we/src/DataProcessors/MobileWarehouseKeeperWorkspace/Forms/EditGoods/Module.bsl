
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Products = Parameters.Products;
	UpdateForm();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Write(Command)
	
	WriteAtServer();
	Close();
	
EndProcedure

&AtClient
Procedure WeightUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("WeightUnitOfMeasure", StandardProcessing, "Weight");
EndProcedure

&AtClient
Procedure VolumeUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("VolumeUnitOfMeasure", StandardProcessing, "VolumeM3");
EndProcedure

&AtClient
Procedure LengthUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("LengthUnitOfMeasure", StandardProcessing, "Length");
EndProcedure

&AtClient
Procedure AreaUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("AreaUnitOfMeasure", StandardProcessing, "AreaTypeOfMeasurement");
EndProcedure

&AtClient
Procedure WeightNumeratorOnChange(Item)
	SetDefaultUnitOfMeasurement("Weight");
EndProcedure

&AtClient
Procedure VolumeNumeratorOnChange(Item)
	SetDefaultUnitOfMeasurement("VolumeM3");
EndProcedure

&AtClient
Procedure LengthNumeratorOnChange(Item)
	SetDefaultUnitOfMeasurement("Length");
EndProcedure

&AtClient
Procedure AreaNumeratorOnChange(Item)
	SetDefaultUnitOfMeasurement("AreaTypeOfMeasurement");
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateForm()
	
	FillPropertyValues(ThisForm, Products);
	
EndProcedure

&AtServer
Procedure WriteAtServer()
	
	ItemProducts_ = Products.GetObject();
	FillPropertyValues(ItemProducts_, ThisForm);
	
	If ItemProducts_.WeightDenominator > 0 Then
		ItemProducts_.WeightUse = True;
	EndIf;
	
	If ItemProducts_.VolumeDenominator > 0 Then
		ItemProducts_.VolumeUse = True;
	EndIf;
	
	If ItemProducts_.LengthDenominator > 0 Then
		ItemProducts_.LengthUse = True;
	EndIf;
	
	If ItemProducts_.AreaDenominator > 0 Then
		ItemProducts_.AreaUse = True;
	EndIf;
	
	ItemProducts_.Write();
	
EndProcedure

&AtClient
Procedure UnitOfMeasurementClick(FieldName, StandardProcessing, MeasureName)
	
	StandardProcessing = False;
	
	NotificationParameters = New Structure("FieldName, MeasureName", FieldName, MeasureName);
	CallbackDescription  = New CallbackDescription("UnitOfMeasurementClickCompletion", ThisObject, NotificationParameters);
	
	NameOfMeasuredValueType = "Enum.TypesOfMeasuredValues." + MeasureName;
	MeasuredValueType     = PredefinedValue(NameOfMeasuredValueType);
	
	Filter          = New Structure("MeasuredValueType", MeasuredValueType);
	FormParameters = New Structure("Filter,CurrentRow", Filter, ThisForm[FieldName]);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.ChoiceForm",
				FormParameters,
				ThisObject,
				,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UnitOfMeasurementClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified = True;
		
		ThisForm[AdditionalParameters.FieldName] = Result;
	EndIf;
	
	Measure = AdditionalParameters.MeasureName;
	MeasureProperties = MeasureProperties(Measure);
	
	ValuePresentationText = NStr("vi = 'Có thể chỉ định số lượng %UnitOfMeasure_% trong các chứng từ';
								|ru = 'Можно указывать количество в %UnitOfMeasure_% в документах';
								|en = 'You can specify quantity in %UnitOfMeasure_% in the documents'; fa = 'You can specify quantity in %UnitOfMeasure_% in the documents';
								|it = 'È possibile indicare la quantità in %UnitOfMeasure_% nei documenti';
								|pl = 'Można określać ilość w %UnitOfMeasure_% w dokumentach';
								|tr = 'Belgelerde miktar %UnitOfMeasure_% olarak belirtilebilir'");
	ValuePresentationText = StrReplace(ValuePresentationText,
	"%UnitOfMeasure_%",
	String(ThisForm[MeasureProperties.UnitOfMeasure]));
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	Measure - String -
// Returns:
// 	Structure - Contains keys:
// 		* Use - String -
// 		* UnitOfMeasure - String -
// 		* Numerator - String -
// 		* Denominator - String -
// 		* CanBeSpecifiedInDocuments - String -
// 		* YouCanSpecifyStringInDocuments - String -
// 		* Indent - String -
// 		* Label - String -
&AtClientAtServerNoContext
Function MeasureProperties(Measure)
	
	MeasureProperties = New Structure;
	MeasureProperties.Insert("Use");
	MeasureProperties.Insert("UnitOfMeasure");
	MeasureProperties.Insert("Numerator");
	MeasureProperties.Insert("Denominator");
	MeasureProperties.Insert("CanBeSpecifiedInDocuments");
	MeasureProperties.Insert("YouCanSpecifyStringInDocuments");
	MeasureProperties.Insert("Indent");
	MeasureProperties.Insert("Label");
	
	If Measure = "VolumeM3" Then
		MeasureProperties.Use = "VolumeUse";
		MeasureProperties.UnitOfMeasure = "VolumeUnitOfMeasure";
		MeasureProperties.Numerator = "VolumeNumerator";
		MeasureProperties.Denominator = "VolumeDenominator";
		MeasureProperties.CanBeSpecifiedInDocuments = "VolumeCanBeSpecifiedInDocuments";
		MeasureProperties.YouCanSpecifyStringInDocuments = "YouCanSpecifyVolumeInTheDocumentsLine";
		MeasureProperties.Indent = "VolumeIndent";
		MeasureProperties.Label = "VolumeLabel";
	ElsIf Measure = "Length" Then
		MeasureProperties.Use = "LengthUse";
		MeasureProperties.UnitOfMeasure = "LengthUnitOfMeasure";
		MeasureProperties.Numerator = "LengthNumerator";
		MeasureProperties.Denominator = "LengthDenominator";
		MeasureProperties.CanBeSpecifiedInDocuments = "YouCanSpecifyLengthInDocuments";
		MeasureProperties.YouCanSpecifyStringInDocuments = "YouCanSpecifyLengthInDocumentsLine";
		MeasureProperties.Indent = "LengthIndent";
		MeasureProperties.Label = "TheLengthOfTheInscription";
	ElsIf Measure = "Width" Then
		MeasureProperties.Use = "WidthToUse";
		MeasureProperties.UnitOfMeasure = "WidthUnitOfMeasure";
		MeasureProperties.Numerator = "WidthNumerator";
		MeasureProperties.Denominator = "WidthDenominator";
		MeasureProperties.CanBeSpecifiedInDocuments = "WidthCanBeSpecifiedInDocuments";
		MeasureProperties.YouCanSpecifyStringInDocuments = "WidthCanBeSpecifiedInDocumentsLine";
		MeasureProperties.Indent = "WidthIndentation";
		MeasureProperties.Label = "WidthLabel";
	ElsIf Measure = "Weight" Then
		MeasureProperties.Use = "WeightUse";
		MeasureProperties.UnitOfMeasure = "WeightUnitOfMeasure";
		MeasureProperties.Numerator = "WeightNumerator";
		MeasureProperties.Denominator = "WeightDenominator";
		MeasureProperties.CanBeSpecifiedInDocuments = "YouCanSpecifyWeightInDocuments";
		MeasureProperties.YouCanSpecifyStringInDocuments = "YouCanSpecifyWeightInDocumentsLine";
		MeasureProperties.Indent = "WeightIndent";
		MeasureProperties.Label = "WeightLabel";
	ElsIf Measure = "AreaTypeOfMeasurement" Then
		MeasureProperties.Use = "AreaUse";
		MeasureProperties.UnitOfMeasure = "AreaUnitOfMeasure";
		MeasureProperties.Numerator = "AreaNumerator";
		MeasureProperties.Denominator = "AreaDenominator";
		MeasureProperties.CanBeSpecifiedInDocuments = "AreaCanBeSpecifiedInDocuments";
		MeasureProperties.YouCanSpecifyStringInDocuments = "YouCanSpecifyAnAreaInDocumentsLine";
		MeasureProperties.Indent = "AreaIndent";
		MeasureProperties.Label = "SquareInscription";
	Else
		Raise StrTemplate(NStr("vi = 'Chưa xác định thuộc tính phương thức %1';
								|ru = 'Не определены свойства меры %1';
								|en = 'Measure %1 properties not defined'; fa = 'Measure %1 properties not defined';
								|it = 'Proprietà di misura %1 non definite';
								|pl = 'Nie określono właściwości miary %1';
								|tr = 'Ölçü özellikleri tanımlanmamış %1'"), Measure);
	EndIf;
	
	Return MeasureProperties;
	
EndFunction

&AtServer
Procedure SetDefaultUnitOfMeasurement(Measure)
	
	If ThisForm[Measure + "UnitOfMeasure"].IsEmpty() Then
		ThisForm[Measure + "UnitOfMeasure"] = MobileWarehouseKeeperWorkspace.DefaultUnitOfMeasurement(Measure);
	EndIf;
	
EndProcedure

#EndRegion