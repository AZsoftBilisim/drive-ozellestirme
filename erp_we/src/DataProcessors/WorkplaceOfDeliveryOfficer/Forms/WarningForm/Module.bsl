// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.WorkplaceOfDeliveryOfficer.TemplateWarning");
	
	QueryText =
	"SELECT
	|	StatesAndDetailsOfDelivery.ReferenceOrder AS ReferenceOrder,
	|	StatesAndDetailsOfDelivery.SpecialTransportationConditionsDescription AS LongDesc,
	|	StatesAndDetailsOfDelivery.RecipientSender AS RecipientSender,
	|	StatesAndDetailsOfDelivery.Address AS Address
	|FROM
	|	InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
	|WHERE
	|	StatesAndDetailsOfDelivery.ReferenceOrder IN(&References)
	|	AND StatesAndDetailsOfDelivery.SpecialTransportationConditions = TRUE
	|
	|ORDER BY
	|	StatesAndDetailsOfDelivery.RecipientSender,
	|	StatesAndDetailsOfDelivery.ReferenceOrder";
	Query = New Query(QueryText);
	Query.SetParameter("References", Parameters.References);
	
	Selection = Query.Execute().Select();
	
	SpreadsheetDocument.Put(Template.GetArea("Indent"));
	
	While Selection.Next() Do
		
		AreaToFillIn = Template.GetArea("TableRow");
		
		TextOfOrder = NStr("vi = '%RecipientSender%, %ReferenceOrder%';
							|ru = '%RecipientSender%, %ReferenceOrder%';
							|en = '%RecipientSender%, %ReferenceOrder%'; fa = '%RecipientSender%, %ReferenceOrder%';
							|it = '%RecipientSender%, %ReferenceOrder%';
							|pl = '%RecipientSender%, %ReferenceOrder%';
							|tr = '%RecipientSender%, %ReferenceOrder%'");
		TextOfOrder = StrReplace(TextOfOrder, "%RecipientSender%", Selection.RecipientSender);
		TextOfOrder = StrReplace(TextOfOrder, "%ReferenceOrder%", Selection.ReferenceOrder);
		AreaToFillIn.Parameters.TextOfOrder = TextOfOrder;
		AreaToFillIn.Parameters.Fill(Selection);
		
		SpreadsheetDocument.Put(AreaToFillIn);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
EndProcedure

#EndRegion