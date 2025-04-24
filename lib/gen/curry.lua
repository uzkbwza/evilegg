---@diagnostic disable: lowercase-global

function curry2(f)
 return function(arg1)
  return function(arg2, ...)
   return f(arg1, arg2, ...)
  end
 end
end	

function curry3(f)
 return function(arg1)
  return function(arg2)
   return function(arg3, ...)
    return f(arg1, arg2, arg3, ...)
   end
  end
 end
end	

function curry4(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4, ...)
     return f(arg1, arg2, arg3, arg4, ...)
    end
   end
  end
 end
end	

function curry5(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5, ...)
      return f(arg1, arg2, arg3, arg4, arg5, ...)
     end
    end
   end
  end
 end
end	

function curry6(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6, ...)
       return f(arg1, arg2, arg3, arg4, arg5, arg6, ...)
      end
     end
    end
   end
  end
 end
end	

function curry7(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7, ...)
        return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, ...)
       end
      end
     end
    end
   end
  end
 end
end	

function curry8(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8, ...)
         return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, ...)
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry9(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9, ...)
          return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, ...)
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry10(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10, ...)
           return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, ...)
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry11(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11, ...)
            return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, ...)
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry12(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12, ...)
             return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, ...)
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry13(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13, ...)
              return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, ...)
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry14(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14, ...)
               return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, ...)
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry15(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15, ...)
                return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, ...)
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end
function curry16(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16, ...)
                 return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, ...)
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry17(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17, ...)
                  return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, ...)
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry18(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18, ...)
                   return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, ...)
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry19(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19, ...)
                    return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, ...)
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry20(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20, ...)
                     return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, ...)
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry21(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21, ...)
                      return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, ...)
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry22(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22, ...)
                       return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, ...)
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry23(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23, ...)
                        return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, ...)
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry24(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24, ...)
                         return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, ...)
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry25(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25, ...)
                          return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, ...)
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end
function curry26(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26, ...)
                           return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, ...)
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry27(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27, ...)
                            return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, ...)
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry28(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28, ...)
                             return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, ...)
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry29(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29, ...)
                              return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, ...)
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry30(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30, ...)
                               return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, ...)
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry31(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31, ...)
                                return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, ...)
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end
function curry32(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32, ...)
                                 return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, ...)
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry33(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33, ...)
                                  return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, ...)
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry34(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34, ...)
                                   return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, ...)
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry35(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35, ...)
                                    return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, ...)
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry36(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36, ...)
                                     return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, ...)
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry37(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37, ...)
                                      return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, ...)
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry38(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38, ...)
                                       return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, ...)
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry39(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39, ...)
                                        return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, ...)
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry40(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40, ...)
                                         return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, ...)
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry41(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41, ...)
                                          return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, ...)
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry42(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42, ...)
                                           return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, ...)
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry43(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43, ...)
                                            return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, ...)
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry44(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44, ...)
                                             return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, ...)
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry45(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45, ...)
                                              return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, ...)
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry46(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46, ...)
                                               return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, ...)
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry47(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47, ...)
                                                return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, ...)
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry48(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48, ...)
                                                 return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, ...)
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry49(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49, ...)
                                                  return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, ...)
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry50(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49)
                                                  return function(arg50, ...)
                                                   return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, arg50, ...)
                                                  end
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry51(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49)
                                                  return function(arg50)
                                                   return function(arg51, ...)
                                                    return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, arg50, arg51, ...)
                                                   end
                                                  end
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry52(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49)
                                                  return function(arg50)
                                                   return function(arg51)
                                                    return function(arg52, ...)
                                                     return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, arg50, arg51, arg52, ...)
                                                    end
                                                   end
                                                  end
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry53(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49)
                                                  return function(arg50)
                                                   return function(arg51)
                                                    return function(arg52)
                                                     return function(arg53, ...)
                                                      return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, arg50, arg51, arg52, arg53, ...)
                                                     end
                                                    end
                                                   end
                                                  end
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry54(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49)
                                                  return function(arg50)
                                                   return function(arg51)
                                                    return function(arg52)
                                                     return function(arg53)
                                                      return function(arg54, ...)
                                                       return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, arg50, arg51, arg52, arg53, arg54, ...)
                                                      end
                                                     end
                                                    end
                                                   end
                                                  end
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry55(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49)
                                                  return function(arg50)
                                                   return function(arg51)
                                                    return function(arg52)
                                                     return function(arg53)
                                                      return function(arg54)
                                                       return function(arg55, ...)
                                                        return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, arg50, arg51, arg52, arg53, arg54, arg55, ...)
                                                       end
                                                      end
                                                     end
                                                    end
                                                   end
                                                  end
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry56(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49)
                                                  return function(arg50)
                                                   return function(arg51)
                                                    return function(arg52)
                                                     return function(arg53)
                                                      return function(arg54)
                                                       return function(arg55)
                                                        return function(arg56, ...)
                                                         return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, arg50, arg51, arg52, arg53, arg54, arg55, arg56, ...)
                                                        end
                                                       end
                                                      end
                                                     end
                                                    end
                                                   end
                                                  end
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry57(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49)
                                                  return function(arg50)
                                                   return function(arg51)
                                                    return function(arg52)
                                                     return function(arg53)
                                                      return function(arg54)
                                                       return function(arg55)
                                                        return function(arg56)
                                                         return function(arg57, ...)
                                                          return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, arg50, arg51, arg52, arg53, arg54, arg55, arg56, arg57, ...)
                                                         end
                                                        end
                                                       end
                                                      end
                                                     end
                                                    end
                                                   end
                                                  end
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry58(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49)
                                                  return function(arg50)
                                                   return function(arg51)
                                                    return function(arg52)
                                                     return function(arg53)
                                                      return function(arg54)
                                                       return function(arg55)
                                                        return function(arg56)
                                                         return function(arg57)
                                                          return function(arg58, ...)
                                                           return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, arg50, arg51, arg52, arg53, arg54, arg55, arg56, arg57, arg58, ...)
                                                          end
                                                         end
                                                        end
                                                       end
                                                      end
                                                     end
                                                    end
                                                   end
                                                  end
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end	

function curry59(f)
 return function(arg1)
  return function(arg2)
   return function(arg3)
    return function(arg4)
     return function(arg5)
      return function(arg6)
       return function(arg7)
        return function(arg8)
         return function(arg9)
          return function(arg10)
           return function(arg11)
            return function(arg12)
             return function(arg13)
              return function(arg14)
               return function(arg15)
                return function(arg16)
                 return function(arg17)
                  return function(arg18)
                   return function(arg19)
                    return function(arg20)
                     return function(arg21)
                      return function(arg22)
                       return function(arg23)
                        return function(arg24)
                         return function(arg25)
                          return function(arg26)
                           return function(arg27)
                            return function(arg28)
                             return function(arg29)
                              return function(arg30)
                               return function(arg31)
                                return function(arg32)
                                 return function(arg33)
                                  return function(arg34)
                                   return function(arg35)
                                    return function(arg36)
                                     return function(arg37)
                                      return function(arg38)
                                       return function(arg39)
                                        return function(arg40)
                                         return function(arg41)
                                          return function(arg42)
                                           return function(arg43)
                                            return function(arg44)
                                             return function(arg45)
                                              return function(arg46)
                                               return function(arg47)
                                                return function(arg48)
                                                 return function(arg49)
                                                  return function(arg50)
                                                   return function(arg51)
                                                    return function(arg52)
                                                     return function(arg53)
                                                      return function(arg54)
                                                       return function(arg55)
                                                        return function(arg56)
                                                         return function(arg57)
                                                          return function(arg58)
                                                           return function(arg59, ...)
                                                            return f(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39, arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49, arg50, arg51, arg52, arg53, arg54, arg55, arg56, arg57, arg58, arg59, ...)
                                                           end
                                                          end
                                                         end
                                                        end
                                                       end
                                                      end
                                                     end
                                                    end
                                                   end
                                                  end
                                                 end
                                                end
                                               end
                                              end
                                             end
                                            end
                                           end
                                          end
                                         end
                                        end
                                       end
                                      end
                                     end
                                    end
                                   end
                                  end
                                 end
                                end
                               end
                              end
                             end
                            end
                           end
                          end
                         end
                        end
                       end
                      end
                     end
                    end
                   end
                  end
                 end
                end
               end
              end
             end
            end
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
end
