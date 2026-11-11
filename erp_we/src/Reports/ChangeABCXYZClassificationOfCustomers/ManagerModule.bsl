#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public
	
// Returns a text description of classification by ABC/XYZ class values
//
// Parameters:
//  ABC - EnumRef.ABCClassification - ABC classification value,
//  XYZ - EnumRef.XYZClassification - the XYZ value of the classification.
//
// Returns:
//   String - string representation of the class
//
Function GetClassificationPresentation(ABC, XYZ) Export

	ABCPresentation = GetClassDescription(ABC);
	PresentationOfXYZ = GetClassDescription(XYZ);
	
	Return ABCPresentation + ", " + PresentationOfXYZ;

EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ChangeABCXYZClassificationOfCustomers);
	DescriptionOfReport.LongDesc = NStr("vi = 'Thay đổi phân loại ABC/XYZ khách hàng.';
										|ru = 'Изменение ABC/XYZ - распределения клиентов.';
										|en = 'Change ABC/XYZ distribution of customers.'; fa = 'Change ABC/XYZ distribution of customers.';
										|it = 'Изменение ABC/XYZ - распределения клиентов.';
										|pl = 'Zmiana ABC/XYZ - podział klientów.';
										|tr = 'ABC/XYZ müşteri dağılımı değişikliği.'");
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion 

#Region Private

// Returns a text description of the class by its value
//
// Parameters:
//  ClassValue - EnumRef.ABCClassification, EnumRef.XYZClassification - the value of the class for
//      which you want to define the description.
//
// Returns:
//   String - string representation of the class
//
Function GetClassDescription(ClassValue)

	If ClassValue = Enums.ABCClassification.EmptyRef() Then
		Return NStr("vi = 'khách hàng tiềm năng(ABC)';
					|ru = 'потенциальный клиент(ABC)';
					|en = 'potential customer (ABC)'; fa = 'potential customer (ABC)';
					|it = 'potenziale cliente (ABC)';
					|pl = 'potencjalny klient(ABC)';
					|tr = 'potansiyel müşteri(ABC)'");
	ElsIf ClassValue = Enums.ABCClassification.NotClassified Then
		Return NStr("vi = 'khách hàng bị mất(ABC)';
					|ru = 'потерянный клиент(ABC)';
					|en = 'lost customer (ABC)'; fa = 'lost customer (ABC)';
					|it = 'cliente perso (ABC)';
					|pl = 'utracony klient(ABC)';
					|tr = 'kaybedilen müşteri(ABC)'");
	ElsIf ClassValue = Enums.XYZClassification.EmptyRef() Then
		Return NStr("vi = 'khách hàng tiềm năng(XYZ)';
					|ru = 'потенциальный клиент(XYZ)';
					|en = 'potential customer (XYZ)'; fa = 'potential customer (XYZ)';
					|it = 'potenziale cliente (XYZ)';
					|pl = 'potencjalny klient(XYZ)';
					|tr = 'potansiyel müşteri(XYZ)'");
	ElsIf ClassValue = Enums.XYZClassification.NotClassified Then
		Return NStr("vi = 'khách hàng bị mất(XYZ)';
					|ru = 'потерянный клиент(XYZ)';
					|en = 'lost customer (XYZ)'; fa = 'lost customer (XYZ)';
					|it = 'cliente perso (XYZ)';
					|pl = 'utracony klient(XYZ)';
					|tr = 'kaybedilen müşteri(XYZ)'");
	Else
		Return String(ClassValue);
	EndIf;

EndFunction

#EndRegion

#EndIf