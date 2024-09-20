module digital_clock(
    input clk,
    input reset,
    input set_but_C,
    input but_U,but_D,but_L,but_R,alarm_sw,
    input trigger,
    output reg alarm_led,
    output reg [1:0] state_led,
    output [4:0]hours_led,
    output [6:0] IO_SSEG,
    output [3:0] IO_SSEG_SEL // FPGA 7-Segment Display
    );

    reg [5:0] seconds;
    reg [4:0] hours;
    reg [5:0] minutes;
    reg [5:0] stop_sec;
    reg [5:0] stop_min;
    
    reg [5:0] alarm_sec;        
    reg [4:0] alarm_hrs;
    reg [5:0] alarm_min;    
    
    reg [3:0] disp_min_ones;
    reg [3:0] disp_min_tens;
    reg [3:0] disp_hours_ones;
    reg [3:0] disp_hours_tens;
   
    reg [1:0] set_state;
   
    reg [0:0] select;
    assign hours_led=hours;
    initial begin
        seconds<=0;
        minutes<=1;
        hours<=12;
        alarm_min<=3;
        alarm_hrs<=12;        
        set_state<=2'b00;
    end    
    
    reg [31:0] counter = 0;
    reg [31:0] blink_cnt =0;
    reg [31:0] prnt_cnt=0;
    parameter max_counter = 100000000;
    parameter stop=7;//minutes tens stop
    parameter alarm=8;//minutes tens
    parameter set=9;//minutes tens
    parameter tme=3;//hours 1stbit
    reg [31:0] set_count = 0;
    parameter set_max = 25000000; 
    reg [31:0] stop_set_count = 0;   
        /* Seven Segment Display */
    sevseg display(.clk(clk),       // Initialize 7-segment display module
        .binary_input_0(disp_min_ones),
        .binary_input_1(disp_min_tens),
        .binary_input_2(disp_hours_ones),
        .binary_input_3(disp_hours_tens),
        .IO_SSEG_SEL(IO_SSEG_SEL),
        .IO_SSEG(IO_SSEG));
    
    always@(posedge clk)begin
             if(counter< max_counter) begin
                       counter<=counter+1;
             end     
             else begin
                     counter<=0;
                     seconds<=seconds+1; 
             end        
          case(set_state)
              2'b00: begin
                if(reset==1) begin
                    seconds<=0;
                    minutes<=0;
                    hours<=0;
                end
//                if(prnt_cnt< max_counter) begin
//                       prnt_cnt<=prnt_cnt+1;
//                       disp_min_tens<=7;
//                end     
//                else begin
//                     prnt_cnt<=0; 
//                end
                
//                disp_min_ones<=minutes%10;
//                disp_min_tens<=minutes/10;
//                disp_hours_ones<=hours%10;
//                disp_hours_tens<=hours/10;

                disp_min_ones<=seconds%10;
                disp_min_tens<=seconds/10;
                disp_hours_ones<=minutes%10;
                disp_hours_tens<=minutes/10;
                
                if(stop_set_count<set_max) begin
                    stop_set_count<=stop_set_count+1;
                end
                else begin
                    if(set_but_C==1) begin
                        set_state<=2'b01;
                        stop_set_count<=0;
                    end
                end
                stop_sec<=0;
                stop_min<=0;
              end
                    
              2'b01:begin
                     if(reset==1) begin
                            stop_sec<=0;
                            stop_min<=0;
                     end                                         
                     else if(stop_set_count< max_counter) begin
                                stop_set_count<=stop_set_count+1;                              
                     end
                     else begin
                        if(trigger==1)begin
                             stop_set_count<=0;
                             stop_sec<=stop_sec+1; 
                        end
                        if(stop_set_count<set_max) begin
                                stop_set_count<=stop_set_count+1;
                         end
                         else begin
                             if(but_D==1) begin
                                stop_sec<=0;         
                             end
                         end
                         
                         if(stop_sec>=59) begin
                                stop_sec<=0;
                                stop_min<=stop_min+1;
                         end
                         if(stop_min>=59) begin
                            stop_min<=0;
                         end
                     end
                         if(stop_set_count<set_max) begin
                                stop_set_count<=stop_set_count+1;
                         end
                         else begin
                             if(set_but_C==1) begin
                                set_state<=2'b10;
                                stop_set_count<=0;
                             end
                         end
//                         alarm_min<=minutes;
//                         alarm_hrs<=hours;
                             disp_min_ones<=stop_sec%10;
                             disp_min_tens<=stop_sec/10;
                             disp_hours_ones<=stop_min%10;
                             disp_hours_tens<=stop_min/10;
              end
              2'b10:begin
                         if(set_count<set_max) begin
                                set_count<=set_count+1;
                         end
                         else begin
                              set_count<=0;
                              if(but_R==1) begin
                                    select<=0;
                              end
                              if(but_L==1) begin
                                    select<=1;
                              end
                              if(select==0) begin
                                if(but_U==1) begin
                                    if(alarm_min==59)begin
                                        alarm_min<=0;
                                        alarm_hrs<=alarm_hrs+1;
                                    end
                                    else
                                        alarm_min<=alarm_min+1;
                                end
                                if(but_D==1) begin
                                    if(alarm_min==0)begin
                                        alarm_min<=59;
                                        alarm_hrs<=alarm_hrs-1;
                                    end
                                    else
                                        alarm_min<=alarm_min-1;
                                end
                              end
                              if(select==1) begin
                                if(but_U==1) begin
                                    if(alarm_hrs==23)begin
                                        alarm_hrs<=0;
                                    end
                                    else
                                        alarm_hrs<=alarm_hrs+1;
                                end
                                if(but_D==1) begin
                                    if(alarm_hrs==0)begin
                                        alarm_hrs<=23;
                                    end
                                    else
                                        alarm_hrs<=alarm_hrs-1;
                                end                                
                              end
                         end
                         if(stop_set_count<set_max) begin
                                stop_set_count<=stop_set_count+1;
                         end
                         else begin
                             if(set_but_C==1) begin
                                set_state<=2'b11;
                                stop_set_count<=0;
                             end
                         end                         
                         disp_min_ones<=alarm_min%10;
                         disp_min_tens<=alarm_min/10;
                         disp_hours_ones<=alarm_hrs%10;
                         disp_hours_tens<=alarm_hrs/10;                                
              end
              2'b11: begin
                         if(reset==1) begin
                            seconds<=0;
                            minutes<=0;
                            hours<=0;
                         end
                         else if(set_count<set_max) begin
                                set_count<=set_count+1;
                         end
                         else begin
                              set_count<=0;
                              if(but_R==1) begin
                                    select<=0;
                              end
                              if(but_L==1) begin
                                    select<=1;
                              end
                            if(select==0) begin
                                if(but_U==1) begin
                                    minutes<=minutes+1;
                                end
                                if(but_D==1) begin
                                    if(minutes==0)begin
                                minutes<=59;
                                hours<=hours-1;
                                    end
                                    else
                                        minutes<=minutes-1;
                                end
                            end
                            if(select==1) begin
                                if(but_U==1) begin
                                    hours<=hours+1;
                                end
                                if(but_D==1) begin
                                    if(hours==0)begin
                                        hours<=23;
                                    end
                                    else
                                        hours<=hours-1;
                                    end
                                end
                            end
                         if(stop_set_count<set_max) begin
                                stop_set_count<=stop_set_count+1;
                         end
                         else begin
                             if(set_but_C==1) begin
                                set_state<=2'b00;
                                stop_set_count<=0;
                             end
                         end                         
                         disp_min_ones<=minutes%10;
                         disp_min_tens<=minutes/10;
                         disp_hours_ones<=hours%10;
                         disp_hours_tens<=hours/10;                         
                    end     
            endcase
             if(seconds>=60) begin
                    seconds<=0;
                    minutes<=minutes+1;
             end
             if(minutes>=60) begin
                minutes<=0;
                hours<=hours+1;
             end
             if(hours>=24) begin
                hours<=0;
             end
             if(alarm_sw==1)begin
                 if(alarm_min==minutes)begin
                        if(alarm_hrs==hours)begin
                            if(blink_cnt<max_counter)begin
                            alarm_led<=1;
                            blink_cnt<=blink_cnt+1;
                            end
                            else if(blink_cnt<2*max_counter)begin
                            alarm_led<=0;
                            blink_cnt<=blink_cnt+1;
                            end
                            else begin
                            blink_cnt<=0;
                            end 
                        end
                        else begin
                            alarm_led<=0;
                        end
                 end       
                 else begin
                    alarm_led<=0;
                 end          
             end
             else begin
                    alarm_led<=0;
             end
          state_led[0]<=set_state[0];
          state_led[1]<=set_state[1];
   end                      
endmodule