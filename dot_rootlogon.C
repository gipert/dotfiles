{
    // nicer color map?
    gStyle->SetPalette(kViridis);
    gStyle->SetNumberContours(255);

    // do not display any of the standard histogram decorations
    gStyle->SetOptStat(false);
    gStyle->SetOptFit(0);

    gStyle->SetCanvasDefH(2*gStyle->GetCanvasDefH());

    // HiDPI settings
    gStyle->SetLineScalePS(1.5);
    gStyle->SetCanvasDefW(2*gStyle->GetCanvasDefW());
    gStyle->SetFrameBorderSize(2*gStyle->GetFrameBorderSize());
    gStyle->SetFrameLineWidth(2*gStyle->GetFrameLineWidth());
    gStyle->SetFuncWidth(2*gStyle->GetFuncWidth());
    gStyle->SetGridWidth(2*gStyle->GetGridWidth());
    gStyle->SetHistLineWidth(2*gStyle->GetHistLineWidth());

    gROOT->ForceStyle();
}
