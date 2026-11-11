// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	CapacityPresentation = "";
	SpaceInMiddle = "";
	If ValueIsFilled(CarryingCapacityInTons) Then
		CapacityPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 t';
																							|ru = '%1 т';
																							|en = '%1 t'; fa = '%1 t';
																							|it = '%1 t';
																							|pl = '%1 t';
																							|tr = '%1 t'"), String(CarryingCapacityInTons));
		SpaceInMiddle = " ";
	EndIf;
	If ValueIsFilled(CapacityInCubicMeters) Then
		CapacityPresentation = CapacityPresentation + SpaceInMiddle
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 m3';
																			|ru = '%1 м3';
																			|en = '%1 m3'; fa = '%1 m3';
																			|it = '%1 m3';
																			|pl = '%1 m3';
																			|tr = '%1 m3'"), String(CapacityInCubicMeters));
	EndIf;
	
EndProcedure

#EndRegion

#EndIf