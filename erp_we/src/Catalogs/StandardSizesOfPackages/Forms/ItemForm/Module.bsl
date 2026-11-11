
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HeightOnChange(Item)
	RecalculateVolume();
EndProcedure

&AtClient
Procedure DepthOnChange(Item)
	RecalculateVolume();
EndProcedure

&AtClient
Procedure WidthOnChange(Item)
	RecalculateVolume();
EndProcedure

&AtClient
Procedure DimensionlessOnChange(Item)
	FormControl();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	FormControl();	
	
EndProcedure

&AtServer
Procedure FormControl()
	
	Items.Height.Enabled  			= Not Object.Dimensionless;
	Items.Depth.Enabled 			= Not Object.Dimensionless;
	Items.Width.Enabled  			= Not Object.Dimensionless;
	Items.VolumeM3.Enabled  			= Not Object.Dimensionless;
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.StandardSizesOfPackages);
	
	Items.VolumeUnitOfMeasure.Enabled 		= CanBeEdited And Not Object.Dimensionless;
	Items.DepthUnitOfMeasure.Enabled 	= CanBeEdited And Not Object.Dimensionless;
	Items.WidthUnitOfMeasure.Enabled 	= CanBeEdited And Not Object.Dimensionless;
	Items.HeightUnitOfMeasure.Enabled 	= CanBeEdited And Not Object.Dimensionless;
	
EndProcedure

&AtServer
Procedure RecalculateVolume()
		
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CAST(&WidthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&WidthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS CoefficientWidth,
	|	CAST(&HeightUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&HeightUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS CoefficientHeight,
	|	CAST(&DepthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&DepthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS CoefficientDepth,
	|	CAST(&VolumeUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&VolumeUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS FactorVolume";
	
	Query.SetParameter("WidthUnitOfMeasure", Object.WidthUnitOfMeasure);
	Query.SetParameter("HeightUnitOfMeasure", Object.HeightUnitOfMeasure);
	Query.SetParameter("DepthUnitOfMeasure", Object.DepthUnitOfMeasure);
	Query.SetParameter("VolumeUnitOfMeasure", Object.VolumeUnitOfMeasure);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do 
		Object.VolumeM3 = Object.Height * Selection.CoefficientHeight * Object.Depth * Selection.CoefficientDepth *
			Object.Width * Selection.CoefficientWidth / Selection.FactorVolume;
	EndDo;
	
EndProcedure

&AtClient
Procedure HeightUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("HeightUnitOfMeasure", StandardProcessing, PredefinedValue("Enum.TypesOfMeasuredValues.Length"));
EndProcedure

&AtClient
Procedure WidthUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("WidthUnitOfMeasure", StandardProcessing, PredefinedValue("Enum.TypesOfMeasuredValues.Length"));
EndProcedure

&AtClient
Procedure DepthUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("DepthUnitOfMeasure", StandardProcessing, PredefinedValue("Enum.TypesOfMeasuredValues.Length"));
EndProcedure

&AtClient
Procedure VolumeUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("VolumeUnitOfMeasure", StandardProcessing, PredefinedValue("Enum.TypesOfMeasuredValues.VolumeM3"));
EndProcedure

&AtClient
Procedure UnitOfMeasurementClick(FieldName, StandardProcessing, MeasuredValueType)
	
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("UnitOfMeasurementClickCompletion", ThisObject, New Structure("FieldName", FieldName));
	
	Filter = New Structure;
	Filter.Insert("MeasuredValueType", MeasuredValueType);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.ChoiceForm",
				New Structure("Filter", Filter),
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
		
		Object[AdditionalParameters.FieldName] = Result;
		
		If AdditionalParameters.FieldName = "VolumeUnitOfMeasure"
			Or AdditionalParameters.FieldName = "DepthUnitOfMeasure"
			Or AdditionalParameters.FieldName = "WidthUnitOfMeasure"
			Or AdditionalParameters.FieldName = "HeightUnitOfMeasure" Then
			
			RecalculateVolume();
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
