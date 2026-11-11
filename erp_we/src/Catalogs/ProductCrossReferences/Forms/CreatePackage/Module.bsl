

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PackageKind                         = Parameters.PackageKind;
	OKEICode                           = Parameters.BaseUnitOfMeasureARCMUCode;
	NumberOfPackages                  = Parameters.NumberOfPackages;
	QuantityInBaseUnitOfMeasure   = Parameters.QuantityInBaseUnitOfMeasure;
	PackageName                = Parameters.PackageName;
	BaseUnitOfMeasureDescription = Parameters.BaseUnitOfMeasureDescription;
	
	ChangeCurPageOfPackageView(PackageKind, Items, NumberOfPackages, QuantityInBaseUnitOfMeasure);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PackageKindOnChange(Item)
	
	ChangeCurPageOfPackageView(PackageKind, Items,
		NumberOfPackages, QuantityInBaseUnitOfMeasure);
		
EndProcedure
	
&AtClient
Procedure SaveChanges(Command)
	
	ClearMessages();
	
	If CheckFilling() Then
		
		ClosingParameters = New Structure;
		ClosingParameters.Insert("PackageKind", PackageKind);
		ClosingParameters.Insert("BaseUnitOfMeasureARCMUCode", OKEICode);
		ClosingParameters.Insert("NumberOfPackages", NumberOfPackages);
		ClosingParameters.Insert("QuantityInBaseUnitOfMeasure", QuantityInBaseUnitOfMeasure);
		ClosingParameters.Insert("PackageName", PackageName);
		ClosingParameters.Insert("BaseUnitOfMeasureDescription", BaseUnitOfMeasureDescription);
	
		Close(ClosingParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ChangeCurPageOfPackageView(Val PackageKind, Items, NumberOfPackages, QuantityInBaseUnitOfMeasure)
		
	If PackageKind = "Package" Then
		If NumberOfPackages <> 1
			And QuantityInBaseUnitOfMeasure = 1 Then
			QuantityInBaseUnitOfMeasure = 0;
		EndIf;
		NumberOfPackages = 1;
		Items.PagesOfPackagingTypes.CurrentPage = Items.PagePackaging;
	ElsIf PackageKind = "Unpacking" Then
		If NumberOfPackages = 1
			And QuantityInBaseUnitOfMeasure <> 1 Then
			NumberOfPackages = 0;
		EndIf;
		QuantityInBaseUnitOfMeasure = 1;
		Items.PagesOfPackagingTypes.CurrentPage = Items.UnpackingPage;
	EndIf;
	
EndProcedure

#EndRegion



